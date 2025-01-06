from django.contrib.auth.models import User
from django.db import models
from decimal import Decimal
from django.db.models.signals import post_save
from django.dispatch import receiver

class Currency(models.Model):
    name = models.CharField(max_length=10, unique=True)  # Уникальное название валюты

    def __str__(self):
        return self.name

class SomBalance(models.Model):
    balance = models.DecimalField(max_digits=20, decimal_places=2, default=0.00)

    def __str__(self):
        return f"Баланс : {self.balance} сом"

class Transaction(models.Model):
    TRANSACTION_TYPES = [
        ('buy', 'Покупка'),
        ('sell', 'Продажа'),
    ]

    currency = models.CharField(max_length=10)  # Название валюты, например, USD, EUR
    amount = models.DecimalField(max_digits=20, decimal_places=2)  # Общая сумма
    exchange_rate = models.DecimalField(max_digits=50, decimal_places=2)  # Курс обмена
    username = models.CharField(max_length=15 ,null=True)
    transaction_type = models.CharField(
        max_length=8,
        choices=TRANSACTION_TYPES,
        default='buy',  # Значение по умолчанию
    )
    timestamp = models.DateTimeField(auto_now_add=True)  # Время создания транзакции

    def __str__(self):
        transaction_type_display = dict(self.TRANSACTION_TYPES).get(self.transaction_type, 'Неизвестно')
        return f"{self.username} : {self.amount} {self.currency} по курсу {self.exchange_rate} ({transaction_type_display}) ({self.timestamp})"

    def update_som_balance(self):
        som_balance = SomBalance.objects.first()
        if not som_balance:
            som_balance = SomBalance.objects.create(balance=Decimal(0.00))  # Если нет записи, создаем

        som_value = self.amount * self.exchange_rate

        if self.transaction_type == 'buy':  # Покупка валюты
            som_balance.balance -= som_value
        elif self.transaction_type == 'sell':  # Продажа валюты
            som_balance.balance += som_value

        som_balance.save()

@receiver(post_save, sender=Transaction)
def update_balance_on_transaction(sender, instance, created, **kwargs):
    if created:
        instance.update_som_balance()