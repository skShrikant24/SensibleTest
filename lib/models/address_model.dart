/// Address entity matching API (GetAddressByUser, AddAddress, UpdateAddress).
class AddressModel {
  final String id;
  final String userID;
  final String addressType;
  final String addressLine1;
  final String addressLine2;
  final String landmark;
  final String area;
  final String city;
  final String district;
  final String state;
  final String pincode;
  final String lon;
  final String lan;

  const AddressModel({
    required this.id,
    required this.userID,
    required this.addressType,
    required this.addressLine1,
    required this.addressLine2,
    required this.landmark,
    required this.area,
    required this.city,
    required this.district,
    required this.state,
    required this.pincode,
    required this.lon,
    required this.lan,
  });

  String get displaySummary {
    final parts = <String>[];
    if (addressLine1.isNotEmpty) parts.add(addressLine1);
    if (area.isNotEmpty) parts.add(area);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (pincode.isNotEmpty) parts.add(pincode);
    return parts.join(', ');
  }

  Map<String, dynamic> toJson() => {
        'ID': id,
        'UserID': userID,
        'AddressType': addressType,
        'AddressLine1': addressLine1,
        'AddressLine2': addressLine2,
        'Landmark': landmark,
        'Area': area,
        'City': city,
        'District': district,
        'State': state,
        'Pincode': pincode,
        'lon': lon,
        'lan': lan,
      };

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => v?.toString().trim() ?? '';
    return AddressModel(
      id: str(json['ID']),
      userID: str(json['UserID']),
      addressType: str(json['AddressType']),
      addressLine1: str(json['AddressLine1']),
      addressLine2: str(json['AddressLine2']),
      landmark: str(json['Landmark']),
      area: str(json['Area']),
      city: str(json['City']),
      district: str(json['District']),
      state: str(json['State']),
      pincode: str(json['Pincode']),
      lon: str(json['lon']),
      lan: str(json['lan']),
    );
  }
}
