from django.urls import path
from exchanger.views import login_view, CurrencyListCreateView , add_worker, workers_list, TransactionView, ClearTransactionView , TransactionHistoryView ,aggregate_transactions, CurrencyDetail, get_som_balance
from django.contrib import admin

urlpatterns = [
    path('login/', login_view, name='login'),
    path('admin/', admin.site.urls),
    path('currencies/', CurrencyListCreateView.as_view(), name='currency-list-create'),
    path('add-worker/', add_worker, name='add_worker'),
    path('workers/', workers_list, name='workers_list'),
    path('transactions/', TransactionView.as_view(), name='transactions'),
    path('clear-transactions/', ClearTransactionView.as_view(), name='clear-transactions'),
    path('api/transaction-history/', TransactionHistoryView.as_view(), name='transaction-history'),
    path('api/transaction-history/<int:id>/', TransactionHistoryView.as_view(), name='transaction_delete'),
    path('aggregate_transactions/', aggregate_transactions, name='aggregate_transactions'),
    path('currencies/<int:pk>/', CurrencyDetail.as_view(), name='currency-detail'),
    path('som_balance', get_som_balance, name='som_balance'),
]
