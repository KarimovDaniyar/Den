# Generated by Django 5.1.4 on 2024-12-29 17:02

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("exchanger", "0008_transaction_transaction_type"),
    ]

    operations = [
        migrations.AddField(
            model_name="transaction",
            name="username",
            field=models.CharField(max_length=15, null=True),
        ),
    ]
