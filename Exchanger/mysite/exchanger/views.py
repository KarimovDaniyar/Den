from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import json
from rest_framework import generics
from exchanger.models import Currency , Transaction
from exchanger.serializers import CurrencySerializer, TransactionSerializer
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.generics import get_object_or_404
from django.db.models import F, Sum, Avg
from django.db import models
from .models import SomBalance



@csrf_exempt
def login_view(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            username = data.get("username")
            password = data.get("password")
            print(f"Username: {username}, Password: {password}")  # Для отладки
            user = authenticate(request, username=username, password=password)
            if user:
                return JsonResponse({"message": "Login successful"}, status=200)
            else:
                return JsonResponse({"message": "Invalid username or password"}, status=200)
        except json.JSONDecodeError:
            return JsonResponse({"message": "Invalid data format"}, status=400)
    return JsonResponse({"message": "Invalid request method"}, status=405)

class CurrencyListCreateView(generics.ListCreateAPIView):
    queryset = Currency.objects.all()
    serializer_class = CurrencySerializer

@csrf_exempt
def add_worker(request):
    if request.method == "POST":
        try:
            data = json.loads(request.body)
            username = data.get("username")
            password = data.get("password")

            if username and password:
                if User.objects.filter(username=username).exists():
                    return JsonResponse({"error": "Username already exists"}, status=400)

                # Создаём пользователя в системе Django
                User.objects.create_user(username=username, password=password)
                return JsonResponse({"message": "Worker added successfully"}, status=201)

            return JsonResponse({"error": "Invalid data"}, status=400)
        except json.JSONDecodeError:
            return JsonResponse({"error": "Invalid JSON format"}, status=400)
    else:
        return JsonResponse({"error": "Method not allowed"}, status=405)

def workers_list(request):
    if request.method == "GET":
        workers = User.objects.values('username', 'email', 'first_name', 'last_name')
        return JsonResponse(list(workers), safe=False)
    else:
        return JsonResponse({'error': 'Invalid request method'}, status=405)

class TransactionView(APIView):
    def get(self, request):
        transactions = Transaction.objects.all()
        serializer = TransactionSerializer(transactions, many=True)
        return Response(serializer.data)

    def post(self, request):
        serializer = TransactionSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class TransactionHistoryView(APIView):
    def get(self, request):
        transaction_type = request.query_params.get('transaction_type')  # buy или sell
        currency = request.query_params.get('currency')  # Валюта, например USD

        # Получение всех транзакций
        transactions = Transaction.objects.all()

        # Фильтрация по типу транзакции
        if transaction_type:
            transactions = transactions.filter(transaction_type=transaction_type)

        # Фильтрация по валюте
        if currency:
            transactions = transactions.filter(currency=currency)

        # Сериализация данных
        serializer = TransactionSerializer(transactions, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)

    def delete(self, request, id=None):
        if id is None:
            return Response(
                {"error": "ID транзакции не указан"},
                status=status.HTTP_400_BAD_REQUEST
            )
        # Попытка найти объект по ID
        transaction = get_object_or_404(Transaction, id=id)

        # Получаем текущий баланс СОМ
        som_balance = SomBalance.objects.first()  # Предполагаем, что существует только один объект

        # Рассчитываем изменение баланса в зависимости от типа транзакции
        if transaction.transaction_type == 'buy':
            som_balance_change = -transaction.amount * transaction.exchange_rate  # Для покупок вычитаем
        elif transaction.transaction_type == 'sell':
            som_balance_change = transaction.amount * transaction.exchange_rate  # Для продаж добавляем

        # Удаление транзакции
        transaction.delete()

        # Обновление баланса СОМ
        if som_balance:
            som_balance.balance += som_balance_change  # Корректируем баланс
            som_balance.save()

        return Response(status=status.HTTP_204_NO_CONTENT)



class ClearTransactionView(APIView):
    def delete(self, request):
        # Удаление всех транзакций
        Transaction.objects.all().delete()

        som_balance = 0.00
        SomBalance.objects.update_or_create(id=1, defaults={'balance': som_balance})

        return Response({"message": "Все транзакции удалены"}, status=status.HTTP_204_NO_CONTENT)

class CurrencyDetail(APIView):
    def delete(self, request, pk):
        try:
            currency = Currency.objects.get(pk=pk)

            # Удаляем все транзакции, связанные с этой валютой
            transactions_to_delete = Transaction.objects.filter(currency=currency)
            transactions_to_delete.delete()

            # Пересчитываем баланс СОМ после удаления валюты
            som_balance = 0
            transactions = Transaction.objects.all()
            for transaction in transactions:
                if transaction.transaction_type == 'buy':
                    som_balance -= transaction.amount * transaction.exchange_rate
                elif transaction.transaction_type == 'sell':
                    som_balance += transaction.amount * transaction.exchange_rate

            currency.delete()

            # Обновляем баланс в базе данных
            SomBalance.objects.update_or_create(id=1, defaults={'balance': som_balance})

            return Response(status=status.HTTP_204_NO_CONTENT)
        except Currency.DoesNotExist:
            return Response({'error': 'Currency not found'}, status=status.HTTP_404_NOT_FOUND)


def aggregate_transactions(request):
    # Группируем данные по валютам
    data = Transaction.objects.values('currency').annotate(
        total_buy_amount=Sum('amount', filter=models.Q(transaction_type='buy')),
        total_sell_amount=Sum('amount', filter=models.Q(transaction_type='sell')),
        avg_buy_rate=Avg('exchange_rate', filter=models.Q(transaction_type='buy')),
        avg_sell_rate=Avg('exchange_rate', filter=models.Q(transaction_type='sell')),
    )

    result = []
    total_profit = 0  # Общий профит

    for entry in data:
        total_sell_amount = entry['total_sell_amount'] or 0
        avg_buy_rate = entry['avg_buy_rate'] or 0
        avg_sell_rate = entry['avg_sell_rate'] or 0

        # Профит для валюты
        profit = total_sell_amount * (avg_sell_rate - avg_buy_rate)
        total_profit += profit

        # Добавляем данные в результат
        result.append({
            'currency': entry['currency'],
            'total_buy_amount': entry['total_buy_amount'] or 0,
            'total_sell_amount': total_sell_amount,
            'avg_buy_rate': round(avg_buy_rate, 2),
            'avg_sell_rate': round(avg_sell_rate, 2),
            'profit': round(profit, 2),
        })

    # Возвращаем данные
    return JsonResponse({
        'transactions': result,
        'total_profit': round(total_profit, 2),
    })

def get_som_balance(request):
    som_balance = SomBalance.objects.first()
    if som_balance:
        return JsonResponse({'balance': som_balance.balance})
    else:
        return JsonResponse({'balance': 0.00})
