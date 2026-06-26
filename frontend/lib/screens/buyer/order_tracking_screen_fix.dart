  // ==================== Timeline ====================
  Widget _buildTimeline() {
    final steps = [
      {'label': 'Order Placed', 'icon': Icons.shopping_bag},
      {'label': 'Preparing', 'icon': Icons.restaurant},
      {'label': 'On The Way', 'icon': Icons.delivery_dining},
      {'label': 'Delivered', 'icon': Icons.check_circle},
    ];

    // Calculate current step based on order status
    int currentStep = 0;
    if (_isDelivered) {
      currentStep = 3;
    } else if (_isDriving) {
      currentStep = 2;
    } else if (_isPreparing) {
      currentStep = 1;
    } else if (_isPending) {
      currentStep = 0;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isComplete = index < currentStep; // Completed steps
            final isActive = index == currentStep; // Current step

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isComplete 
                          ? Colors.green 
                          : (isActive ? const Color(0xFF2A7DE1) : Colors.grey.shade200),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isComplete ? Icons.check : step['icon'] as IconData,
                      size: 16,
                      color: (isComplete || isActive) ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['label'] as String,
                          style: TextStyle(
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            color: (isComplete || isActive) ? const Color(0xFF0A1A2B) : Colors.grey.shade600,
                          ),
                        ),
                        if (isActive && !_isDelivered)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'In progress...',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2A7DE1),
                              ),
                            ),
                          ),
                        if (isComplete && index == steps.length - 1)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Delivered! 🎉',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
