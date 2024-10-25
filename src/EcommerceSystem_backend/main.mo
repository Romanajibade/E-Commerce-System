import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Float "mo:base/Float";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Time "mo:base/Time";

actor {
  type ProductId = Nat;
  type OrderId = Nat;

  type Product = {
    id : ProductId;
    name : Text;
    description : Text;
    price : Float;
    stock : Nat;
  };

  type OrderItem = {
    productId : ProductId;
    quantity : Nat;
  };

  type Order = {
    id : OrderId;
    customerId : Text;
    items : [OrderItem];
    totalAmount : Float;
    createdAt : Time.Time;
  };

  var products = Buffer.Buffer<Product>(0);
  var orders = Buffer.Buffer<Order>(0);

  public func addProduct(name : Text, description : Text, price : Float, initialStock : Nat) : async ProductId {
    let productId = products.size();
    let newProduct : Product = {
      id = productId;
      name = name;
      description = description;
      price = price;
      stock = initialStock;
    };
    products.add(newProduct);
    productId;
  };

  public query func getProduct(productId : ProductId) : async ?Product {
    if (productId < products.size()) {
      ?products.get(productId);
    } else {
      null;
    };
  };

  public func updateProductStock(productId : ProductId, newStock : Nat) : async () {
    if (productId < products.size()) {
      var product = products.get(productId);
      product := {
        id = product.id;
        name = product.name;
        description = product.description;
        price = product.price;
        stock = newStock;
      };
      products.put(productId, product);
    };
  };

  public func createOrder(customerId : Text, orderItems : [OrderItem]) : async ?OrderId {
    var totalAmount : Float = 0;
    var validOrder = true;

    for (item in orderItems.vals()) {
      switch (await getProduct(item.productId)) {
        case (null) {
          validOrder := false;
        };
        case (?product) {
          if (product.stock < item.quantity) {
            validOrder := false;
          } else {
            totalAmount += product.price * Float.fromInt(item.quantity);
            await updateProductStock(item.productId, product.stock - item.quantity);
          };
        };
      };
    };

    if (validOrder) {
      let orderId = orders.size();
      let newOrder : Order = {
        id = orderId;
        customerId = customerId;
        items = orderItems;
        totalAmount = totalAmount;
        createdAt = Time.now();
      };
      orders.add(newOrder);
      ?orderId;
    } else {
      null;
    };
  };

  public query func getOrder(orderId : OrderId) : async ?Order {
    if (orderId < orders.size()) {
      ?orders.get(orderId);
    } else {
      null;
    };
  };

  public query func getProductCatalog() : async [Product] {
    Buffer.toArray(products);
  };

  public query func getSalesStatistics() : async {
    totalOrders : Nat;
    totalRevenue : Float;
    averageOrderValue : Float;
  } {
    var totalOrders = orders.size();
    var totalRevenue : Float = 0;

    for (order in orders.vals()) {
      totalRevenue += order.totalAmount;
    };

    let averageOrderValue = if (totalOrders == 0) 0.0 else totalRevenue / Float.fromInt(totalOrders);

    {
      totalOrders = totalOrders;
      totalRevenue = totalRevenue;
      averageOrderValue = averageOrderValue;
    };
  };
};