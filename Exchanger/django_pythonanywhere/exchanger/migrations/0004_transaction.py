# Generated by Django 5.1.4 on 2024-12-29 05:36

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("exchanger", "0003_delete_worker"),
    ]

    operations = [
        migrations.CreateModel(
            name="Transaction",
            fields=[
                (
                    "id",
                    models.BigAutoField(
                        auto_created=True,
                        primary_key=True,
                        serialize=False,
                        verbose_name="ID",
                    ),
                ),
                ("worker_name", models.CharField(max_length=100)),
                ("currency", models.CharField(max_length=10)),
                ("rate", models.FloatField()),
                ("amount", models.FloatField()),
                ("total", models.FloatField()),
                (
                    "transaction_type",
                    models.CharField(
                        choices=[("buy", "Покупка"), ("sell", "Продажа")], max_length=10
                    ),
                ),
                ("created_at", models.DateTimeField(auto_now_add=True)),
            ],
        ),
    ]
