# Generated by Django 5.1.4 on 2024-12-29 08:37

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ("exchanger", "0004_transaction"),
    ]

    operations = [
        migrations.DeleteModel(
            name="Transaction",
        ),
    ]
