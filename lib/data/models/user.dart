/// Usuario de JSONPlaceholder, aplanado a los campos que muestra la app.
///
/// [toJson] es simétrico con [User.fromJson] para poder guardar el usuario
/// completo en SQLite y leerlo sin conexión.
class User {
  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.website,
    required this.companyName,
    required this.city,
  });

  final int id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String website;
  final String companyName;
  final String city;

  factory User.fromJson(Map<String, dynamic> json) {
    final company = json['company'] as Map<String, dynamic>?;
    final address = json['address'] as Map<String, dynamic>?;
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      username: json['username'] as String? ?? '',
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '',
      website: json['website'] as String? ?? '',
      companyName: company?['name'] as String? ?? '',
      city: address?['city'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'username': username,
    'email': email,
    'phone': phone,
    'website': website,
    'company': {'name': companyName},
    'address': {'city': city},
  };

  @override
  bool operator ==(Object other) =>
      other is User &&
      other.id == id &&
      other.name == name &&
      other.username == username &&
      other.email == email &&
      other.phone == phone &&
      other.website == website &&
      other.companyName == companyName &&
      other.city == city;

  @override
  int get hashCode =>
      Object.hash(id, name, username, email, phone, website, companyName, city);
}
