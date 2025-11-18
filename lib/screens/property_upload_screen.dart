import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '/models/property_model.dart';
import '/services/image_service.dart'; // ✅ IMPORT ADDED
import '/themes.dart';

class PropertyUploadScreen extends StatefulWidget {
  final Property? property;

  const PropertyUploadScreen({this.property, Key? key}) : super(key: key);

  @override
  _PropertyUploadScreenState createState() => _PropertyUploadScreenState();
}

class _PropertyUploadScreenState extends State<PropertyUploadScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactController = TextEditingController();
  final _bedroomsController = TextEditingController(text: '1');
  final _bathroomsController = TextEditingController(text: '1');

  // Form values
  String _selectedType = 'Student Hostel';
  String _selectedStatus = 'available';
  List<String> _imageUrls = [];
  bool _isLoading = false;
  bool _uploadingImages = false;

  // Property types
  final List<String> _propertyTypes = [
    'Student Hostel',
    'Single Room',
    'Chamber & Hall',
    'Single Room SC',
    '2 Bedroom SC',
    '3 Bedroom SC',
    '4 Bedroom SC',
    'Furnitures',
    'Lands',
    'Shops',
    'Short Stay'
  ];

  // GraphQL Mutation
  final String createPropertyMutation = '''
    mutation CreateProperty(\$input: PropertyInput!) {
      createProperty(input: \$input) {
        id
        title
        location
        price
        type
        status
        images
        bedrooms
        bathrooms
        rating
        createdAt
      }
    }
  ''';

  @override
  void initState() {
    super.initState();
    // If editing, pre-fill form
    if (widget.property != null) {
      _prefillForm();
    }
  }

  void _prefillForm() {
    final property = widget.property!;
    _titleController.text = property.title;
    _locationController.text = property.location;
    _priceController.text = property.price.toString();
    _descriptionController.text = property.description;
    _contactController.text = property.contact ?? '';
    _bedroomsController.text = property.bedrooms.toString();
    _bathroomsController.text = property.bathrooms.toString();
    _selectedType = property.type;
    _selectedStatus = property.status;
    _imageUrls = List<String>.from(property.images);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.property != null ? 'Edit Property' : 'Add New Property'),
        backgroundColor: AppTheme.primaryRed,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildImageUploadSection(),
              const SizedBox(height: 20),
              _buildBasicInfoSection(),
              const SizedBox(height: 20),
              _buildDetailsSection(),
              const SizedBox(height: 30),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Property Images', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        // Image preview
        Container(
          height: 120,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _imageUrls.isEmpty
              ? const Center(child: Text('No images selected', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _imageUrls.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _imageUrls[index],
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[200],
                      child: const Icon(Icons.error, color: Colors.red),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Upload button
        _uploadingImages
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton.icon(
          icon: const Icon(Icons.photo_library, size: 20),
          label: const Text('Select Images from Gallery'),
          onPressed: _pickFromGallery,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryRed,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Basic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Property Title',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value!.isEmpty ? 'Property title is required' : null,
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Location',
            border: OutlineInputBorder(),
          ),
          validator: (value) => value!.isEmpty ? 'Location is required' : null,
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _contactController,
          decoration: const InputDecoration(
            labelText: 'Contact Number (Optional)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: _selectedType,
          items: _propertyTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
          onChanged: (value) => setState(() => _selectedType = value!),
          decoration: const InputDecoration(
            labelText: 'Property Type',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Property Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        TextFormField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Monthly Rent (GHC)',
            prefixText: 'GHC ',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value!.isEmpty) return 'Price is required';
            if (double.tryParse(value) == null) return 'Enter valid price';
            return null;
          },
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _bedroomsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Bedrooms',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _bathroomsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Bathrooms',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        DropdownButtonFormField<String>(
          value: _selectedStatus,
          items: const [
            DropdownMenuItem(value: 'available', child: Text('Available')),
            DropdownMenuItem(value: 'taken', child: Text('Taken')),
            DropdownMenuItem(value: 'pending', child: Text('Pending')),
          ],
          onChanged: (value) => setState(() => _selectedStatus = value!),
          decoration: const InputDecoration(
            labelText: 'Status',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description (Optional)',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Mutation(
      options: MutationOptions(
        document: gql(createPropertyMutation),
        onCompleted: (data) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Property ${widget.property != null ? 'updated' : 'added'} successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        },
        onError: (error) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save property: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      ),
      builder: (RunMutation runMutation, QueryResult? result) {
        return ElevatedButton(
          onPressed: _isLoading ? null : () => _submitForm(runMutation),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryRed,
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          )
              : Text(widget.property != null ? 'Update Property' : 'Add Property'),
        );
      },
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      print('📸 Picking images from gallery...');
      final images = await ImageService.pickImages(maxImages: 10); // ✅ NOW WORKS

      if (images.isEmpty) {
        print('❌ No images selected');
        return;
      }

      print('📤 Uploading ${images.length} images...');
      setState(() => _uploadingImages = true);

      // Use the ImageService
      final uploadedUrls = await ImageService.uploadImages(images); // ✅ NOW WORKS

      print('✅ Uploaded ${uploadedUrls.length} images');

      setState(() {
        _imageUrls.addAll(uploadedUrls);
        _uploadingImages = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${uploadedUrls.length} images added successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('❌ Error in image pick/upload: $e');
      setState(() => _uploadingImages = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add images: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _submitForm(RunMutation runMutation) {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final propertyData = {
        'title': _titleController.text,
        'location': _locationController.text,
        'price': double.parse(_priceController.text),
        'type': _selectedType,
        'status': _selectedStatus,
        'description': _descriptionController.text,
        'images': _imageUrls,
        'bedrooms': int.tryParse(_bedroomsController.text) ?? 1,
        'bathrooms': int.tryParse(_bathroomsController.text) ?? 1,
        'rating': 4.5, // Default rating
        'contact': _contactController.text.isEmpty ? null : _contactController.text,
      };

      runMutation({'input': propertyData});
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    super.dispose();
  }
}