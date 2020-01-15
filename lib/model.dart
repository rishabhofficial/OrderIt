class CompanyData {
  String name;
  String email;
  String cc;
  CompanyData({this.name, this.email, this.cc});

  void disp() {
    name = "";
    email = "";
    cc = "";
  }
  toJson(){
    return{
      "compName":name,
      "compEmail":email,
      "compCC": cc
  };

  }
}


class ProductData {
  String name;
  String pack;
  String qty;
  String division = null;
  ProductData({this.name, this.pack, this.qty, this.division});

  toJson() {
    return {
      "prodName": name,
      "prodPack": pack,
      "prodQty": qty,
      "prodDivision": division
    };
  }
}
