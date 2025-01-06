from rest_framework import serializers
from .models import Currency, Transaction

class CurrencySerializer(serializers.ModelSerializer):
    class Meta:
        model = Currency
        fields = ['id', 'name']


class TransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Transaction
        fields = ['id','currency', 'amount', 'exchange_rate', 'transaction_type', 'username', 'timestamp']