import 'package:flutter/material.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  String _selectedLayer = 'parcels';
  bool _showLegend = true;

  final List<Map<String, dynamic>> _parcels = [
    {
      'id': '1',
      'name': 'Parcel A-001',
      'area': '500 sq m',
      'owner': 'John Doe',
      'status': 'Registered',
      'coordinates': '0.0, 0.0',
    },
    {
      'id': '2',
      'name': 'Parcel A-002',
      'area': '750 sq m',
      'owner': 'Jane Smith',
      'status': 'Pending',
      'coordinates': '0.001, 0.001',
    },
    {
      'id': '3',
      'name': 'Parcel A-003',
      'area': '300 sq m',
      'owner': 'Bob Johnson',
      'status': 'Registered',
      'coordinates': '0.002, 0.002',
    },
  ];

  final List<Map<String, dynamic>> _adminUnits = [
    {
      'id': '1',
      'name': 'Nyamira County',
      'type': 'County',
      'population': '590,013',
      'area': '531.3 km²',
    },
    {
      'id': '2',
      'name': 'Nyamira Sub-County',
      'type': 'Sub-County',
      'population': '150,000',
      'area': '120.5 km²',
    },
    {
      'id': '3',
      'name': 'Luanda Ward',
      'type': 'Ward',
      'population': '45,000',
      'area': '35.2 km²',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EDAMS Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: () {
              _showLayerSelector();
            },
          ),
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              setState(() {
                _showLegend = !_showLegend;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Map Controls
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Map Layer',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    value: _selectedLayer,
                    items: const [
                      DropdownMenuItem(value: 'parcels', child: Text('Land Parcels')),
                      DropdownMenuItem(value: 'admin', child: Text('Administrative Units')),
                      DropdownMenuItem(value: 'zoning', child: Text('Zoning Areas')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedLayer = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    _showSearchDialog();
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('Search'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Map Area (Placeholder)
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Stack(
                children: [
                  // Map placeholder
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.map,
                          size: 64,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Map View - $_selectedLayer',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Interactive map will be displayed here',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Legend
                  if (_showLegend)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _buildLegend(),
                    ),

                  // Sample markers
                  if (_selectedLayer == 'parcels')
                    ..._buildParcelMarkers(),
                ],
              ),
            ),
          ),

          // Data Panel
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: _buildDataPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Legend',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_selectedLayer == 'parcels') ...[
            _buildLegendItem('Registered', Colors.green),
            _buildLegendItem('Pending', Colors.orange),
            _buildLegendItem('Disputed', Colors.red),
          ] else if (_selectedLayer == 'admin') ...[
            _buildLegendItem('County', Colors.blue),
            _buildLegendItem('Sub-County', Colors.purple),
            _buildLegendItem('Ward', Colors.teal),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  List<Widget> _buildParcelMarkers() {
    return _parcels.asMap().entries.map((entry) {
      final index = entry.key;
      final parcel = entry.value;
      final status = parcel['status'] as String;
      
      Color markerColor;
      switch (status) {
        case 'Registered':
          markerColor = Colors.green;
          break;
        case 'Pending':
          markerColor = Colors.orange;
          break;
        default:
          markerColor = Colors.red;
      }

      return Positioned(
        left: 100 + (index * 80.0),
        top: 100 + (index * 60.0),
        child: GestureDetector(
          onTap: () => _showParcelDetails(parcel),
          child: Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: markerColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.location_on,
                  size: 12,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  parcel['name'],
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildDataPanel() {
    if (_selectedLayer == 'parcels') {
      return _buildParcelsPanel();
    } else if (_selectedLayer == 'admin') {
      return _buildAdminPanel();
    } else {
      return _buildZoningPanel();
    }
  }

  Widget _buildParcelsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Land Parcels',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: _parcels.length,
            itemBuilder: (context, index) {
              final parcel = _parcels[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(parcel['status']),
                    child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                  ),
                  title: Text(parcel['name']),
                  subtitle: Text('${parcel['area']} • ${parcel['owner']}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(parcel['status']).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      parcel['status'],
                      style: TextStyle(
                        color: _getStatusColor(parcel['status']),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  onTap: () => _showParcelDetails(parcel),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdminPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Administrative Units',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: _adminUnits.length,
            itemBuilder: (context, index) {
              final unit = _adminUnits[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF2E7D32),
                    child: Icon(Icons.location_city, color: Colors.white),
                  ),
                  title: Text(unit['name']),
                  subtitle: Text('${unit['type']} • ${unit['population']} people'),
                  trailing: Text(
                    unit['area'],
                    style: const TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildZoningPanel() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_city, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Zoning Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Zoning data will be displayed here'),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Registered':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Disputed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showLayerSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Map Layer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Land Parcels'),
              subtitle: const Text('Show individual land parcels'),
              value: 'parcels',
              groupValue: _selectedLayer,
              onChanged: (value) {
                setState(() {
                  _selectedLayer = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Administrative Units'),
              subtitle: const Text('Show county, sub-county, and ward boundaries'),
              value: 'admin',
              groupValue: _selectedLayer,
              onChanged: (value) {
                setState(() {
                  _selectedLayer = value!;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Zoning Areas'),
              subtitle: const Text('Show land use zoning classifications'),
              value: 'zoning',
              groupValue: _selectedLayer,
              onChanged: (value) {
                setState(() {
                  _selectedLayer = value!;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Parcels'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Parcel Number',
                hintText: 'Enter parcel number to search',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Owner Name',
                hintText: 'Enter owner name to search',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showParcelDetails(Map<String, dynamic> parcel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(parcel['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Area:', parcel['area']),
            _buildDetailRow('Owner:', parcel['owner']),
            _buildDetailRow('Status:', parcel['status']),
            _buildDetailRow('Coordinates:', parcel['coordinates']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
