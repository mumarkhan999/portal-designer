# Generated by Django 1.11.21 on 2019-06-13 19:55

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('pages', '0003_programpage_uuid'),
    ]

    operations = [
        migrations.AlterField(
            model_name='programpage',
            name='uuid',
            field=models.UUIDField(editable=False, unique=True),
        ),
    ]
