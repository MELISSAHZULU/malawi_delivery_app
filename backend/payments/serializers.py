from rest_framework import serializers
from .models import PaymentTransaction

class PaymentTransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = PaymentTransaction
        fields = [
            'id', 'transaction_id', 'amount', 'currency',
            'paychangu_reference', 'mobile_number', 'operator',
            'status', 'created_at', 'completed_at'
        ]
        read_only_fields = ['transaction_id', 'created_at']

class PaymentInitiateSerializer(serializers.Serializer):
    order_id = serializers.IntegerField()
    amount = serializers.DecimalField(max_digits=10, decimal_places=2)
    currency = serializers.CharField(default='MWK')
    mobile_number = serializers.CharField(max_length=15)
    operator = serializers.CharField(max_length=10)
    
    def validate(self, data):
        if data['amount'] <= 0:
            raise serializers.ValidationError("Amount must be greater than 0")
        return data