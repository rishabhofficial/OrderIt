class CompanyData {
  String name;
  String email;
  String cc;
  String mailingName;
  String mailingLocation;
  CompanyData({this.name, this.email, this.cc, this.mailingLocation,this.mailingName});

  // void disp() {
  //   name = "";
  //   email = "";
  //   cc = "";
  // }
  toJson(){
    return{
      "compName":name,
      "compEmail":email,
      "compCC": cc,
      "compMailingName": mailingName,
      "compMailingLocation" : mailingLocation
  };

  }
}

class PartyData {
  String name;
  DateTime dateTime;
  String email;
  double defaultDiscount;
  PartyData({this.name, this.dateTime, this.email, this.defaultDiscount});


  toJson(){
    return{
      "partyName":name,
      "partyEmail":email,
      "partyDate": dateTime,
      "partyDefaultDiscount": defaultDiscount
  };

  }
}


class ProductData {
  String name;
  String pack;
  String qty;
  String compCode;
  String division = null;
  String expiryDate;
  int deal1 = 0;
  int deal2 = 0;
  double mrp;
  String batchNumber;
  double amount;

  ProductData({this.name, this.pack, this.qty, this.division, this.expiryDate, this.deal1, this.deal2,this.mrp,this.batchNumber,this.compCode});

  toJson() {
    return {
      "compCode": compCode,
      "prodName": name,
      "prodPack": pack,
      "prodQty": qty,
      "prodDivision": division,
      "prodExpiryDate": expiryDate,
      "prodBatchNumber": batchNumber,
      "prodMrp": mrp,
      "prodDeal1": deal1,
      "prodDeal2": deal2,
      "amount": amount
    };
  }
}
