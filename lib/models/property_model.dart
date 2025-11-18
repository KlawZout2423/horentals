class Property {
  final int id;
  final String title;
  final String location;
  final String? contact;
  final double price;
  final String description; // Changed from String? to String
  final String? imageUrl;
  final List<String> images;
  final String type; // Changed from String? to String
  final String status; // Changed from String? to String
  final int bedrooms; // Changed from int? to int
  final int bathrooms; // Changed from int? to int
  final double rating; // Changed from double? to double
  final DateTime? createdAt;
  final Company company;
  final User owner;

  Property({
    required this.id,
    required this.title,
    required this.location,
    this.contact,
    required this.price,
    required this.description, // Now required
    this.imageUrl,
    required this.images,
    required this.type, // Now required
    required this.status, // Now required
    required this.bedrooms, // Now required
    required this.bathrooms, // Now required
    required this.rating, // Now required
    this.createdAt,
    required this.company,
    required this.owner,
  });

  // Helper getter for isAvailable
  bool get isAvailable => status.toLowerCase() != 'taken';

  // Convert from GraphQL JSON with null safety
  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as int,
      title: json['title'] as String? ?? 'Untitled Property',
      location: json['location'] as String? ?? 'Unknown Location',
      contact: json['contact'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '', // Default empty string
      imageUrl: json['imageUrl'] as String?,
      images: List<String>.from(json['images'] ?? []),
      type: json['type'] as String? ?? 'Other', // Default type
      status: json['status'] as String? ?? 'available', // Default status
      bedrooms: json['bedrooms'] as int? ?? 1, // Default 1 bedroom
      bathrooms: json['bathrooms'] as int? ?? 1, // Default 1 bathroom
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0, // Default 0 rating
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      company: Company.fromJson(json['company']),
      owner: User.fromJson(json['owner']),
    );
  }

  // Convert to GraphQL Input
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'location': location,
      'contact': contact,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'images': images,
      'type': type,
      'status': status,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'rating': rating,
    };
  }

  // For creating new property
  Map<String, dynamic> toInputJson() {
    return {
      'title': title,
      'location': location,
      'contact': contact,
      'price': price,
      'description': description,
      'images': images,
      'type': type,
      'status': status,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'rating': rating,
    };
  }

  // Copy with method
  Property copyWith({
    int? id,
    String? title,
    String? location,
    String? contact,
    double? price,
    String? description,
    String? imageUrl,
    List<String>? images,
    String? type,
    String? status,
    int? bedrooms,
    int? bathrooms,
    double? rating,
    DateTime? createdAt,
    Company? company,
    User? owner,
  }) {
    return Property(
      id: id ?? this.id,
      title: title ?? this.title,
      location: location ?? this.location,
      contact: contact ?? this.contact,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      type: type ?? this.type,
      status: status ?? this.status,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
      company: company ?? this.company,
      owner: owner ?? this.owner,
    );
  }
}

class Company {
  final int id;
  final String name;
  final String? logoUrl;
  final String contact;
  final bool isOwnCompany;

  Company({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.contact,
    required this.isOwnCompany,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown Company',
      logoUrl: json['logoUrl'] as String?,
      contact: json['contact'] as String? ?? 'No contact',
      isOwnCompany: json['isOwnCompany'] as bool? ?? false,
    );
  }
}

class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Unknown User',
      email: json['email'] as String? ?? 'No email',
      role: json['role'] as String? ?? 'user',
      phone: json['phone'] as String?,
    );
  }
}