# Generated by Django 1.11.21 on 2019-06-11 16:24

import designer.apps.branding.models
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    initial = True

    dependencies = [
        ('wagtailimages', '0019_delete_filter'),
    ]

    operations = [
        migrations.CreateModel(
            name='Branding',
            fields=[
                ('id', models.AutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('organization_logo_alt_text', models.CharField(default='', max_length=256, verbose_name='Logo Alt Text')),
                ('banner_border_color', models.CharField(blank=True, default='#FFFFFF', max_length=7, null=True, validators=[designer.apps.branding.models.validate_hexadecimal_color])),
                ('cover_image', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='+', to='wagtailimages.Image', verbose_name='Cover Image')),
                ('organization_logo_image', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='+', to='wagtailimages.Image', verbose_name='Logo Image')),
                ('texture_image', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='+', to='wagtailimages.Image', verbose_name='Texture Image')),
            ],
        ),
    ]
