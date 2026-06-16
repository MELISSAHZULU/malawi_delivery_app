import 'package:flutter/material.dart';

class SalesAnalyticsScreen extends StatelessWidget {
  const SalesAnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Analytics'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date range selector
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Today'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Week'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Month'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Year'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats cards
            Row(
              children: [
                _buildStatCard('Revenue', 'MWK 487K', Icons.attach_money, Colors.green),
                _buildStatCard('Orders', '156', Icons.shopping_bag, Colors.blue),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard('Avg. Order', 'MWK 3,120', Icons.trending_up, Colors.purple),
                _buildStatCard('Rating', '4.8 ★', Icons.star, Colors.amber),
              ],
            ),
            const SizedBox(height: 24),

            // Chart placeholder
            Container(
              height: 200,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sales Overview',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildBar(30, 'Mon'),
                        _buildBar(45, 'Tue'),
                        _buildBar(60, 'Wed'),
                        _buildBar(80, 'Thu'),
                        _buildBar(70, 'Fri'),
                        _buildBar(90, 'Sat'),
                        _buildBar(50, 'Sun'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recent orders
            const Text(
              'Recent Orders',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      child: Text('${index + 1}'),
                    ),
                    title: Text('Order #MW-${2840 + index}'),
                    subtitle: Text('MWK ${(index + 1) * 1000}'),
                    trailing: Chip(
                      label: Text(
                        ['Completed', 'Processing', 'Delivered'][index],
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: [Colors.green, Colors.orange, Colors.blue][index],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBar(double height, String label) {
    return Column(
      children: [
        Container(
          height: height,
          width: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF2A7DE1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
