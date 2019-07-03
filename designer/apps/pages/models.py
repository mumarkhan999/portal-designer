""" Page models """
import uuid

from django.db import models
from wagtail.wagtailcore.models import Page
from wagtail.wagtailcore.fields import RichTextField
from wagtail.wagtailadmin.edit_handlers import FieldPanel


class IndexPage(Page):
    body = RichTextField(blank=True)

    content_panels = Page.content_panels + [
        FieldPanel('body', classname="full"),
    ]


class ProgramPage(Page):
    body = RichTextField(blank=True)
    uuid = models.UUIDField(unique=True)

    content_panels = Page.content_panels + [
        FieldPanel('body', classname="full"),
    ]
