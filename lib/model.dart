class CompanyData {
  String name;
  String email;
  String cc;
  String mailingName;
  String mailingLocation;
  List<dynamic> codes;
  String compCode;
  CompanyData({
    this.name,
    this.email,
    this.cc,
    this.mailingLocation,
    this.mailingName,
    this.codes,
    this.compCode,
  });

  // void disp() {
  //   name = "";
  //   email = "";
  //   cc = "";
  // }
  toJson() {
    return {
      "compName": name,
      "compEmail": email,
      "compCC": cc,
      "compMailingName": mailingName,
      "compMailingLocation": mailingLocation,
      "codes": codes,
      "compCode": compCode
    };
  }
}

class PartyData {
  String name;
  DateTime dateTime;
  String email;
  double defaultDiscount;
  String partyCode;
  PartyData({
    this.name,
    this.dateTime,
    this.email,
    this.defaultDiscount,
    this.partyCode,
  });

  toJson() {
    return {
      "partyName": name,
      "partyEmail": email,
      "partyDate": dateTime,
      "partyDefaultDiscount": defaultDiscount,
      "partyCode": partyCode
    };
  }
}

class ProductData {
  String icode;
  String name;
  String pack;
  String qty;
  String compCode;
  String division;
  String expiryDate;
  int deal1;
  int deal2;
  double mrp;
  String batchNumber;
  double amount;

  ProductData({
    this.icode,
    this.name,
    this.pack,
    this.qty,
    this.division,
    this.expiryDate,
    this.deal1,
    this.deal2,
    this.mrp,
    this.batchNumber,
    this.compCode,
    this.amount,
  });

  toJson() {
    return {
      "compCode": compCode,
      "prodIcode": icode,
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

class ExpiryProductData {
  String name;
  String pack;
  String qty;
  String compCode;
  String division;
  String expiryDate;
  int deal1;
  int deal2;
  double mrp;
  String batchNumber;
  double amount;
  String partyName;
  String colDocId;
  String docId;

  ExpiryProductData({
    this.name,
    this.pack,
    this.qty,
    this.division,
    this.expiryDate,
    this.deal1,
    this.deal2,
    this.mrp,
    this.batchNumber,
    this.compCode,
    this.amount,
    this.partyName,
    this.colDocId,
    this.docId,
  });
}
