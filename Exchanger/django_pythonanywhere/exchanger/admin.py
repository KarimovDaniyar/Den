from django.contrib import admin
from .models import Transaction



@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ('currency', 'amount', 'exchange_rate', 'get_transaction_type_display','username' ,'timestamp')
    list_filter = ('transaction_type', 'currency', 'username')

    def get_transaction_type_display(self, obj):
        return dict(Transaction.TRANSACTION_TYPES).get(obj.transaction_type, 'Неизвестно')
    get_transaction_type_display.short_description = 'Тип транзакции'
