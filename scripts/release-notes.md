---
title: Release Notes
---

# Release Notes

{% for release in releases -%}
## {% if release.is_released %}<a href="https://github.com/inseven/reconnect/releases/tag/{{ release.version }}">{{ release.version }}</a>{% else %}{{ release.version }} (Unreleased){% endif %}
{% for section in release.sections %}
**{{ section.title }}**

{% for change in section.changes | reverse -%}
- {{ change.description }}{% if change.scope %}{{ change.scope }}{% endif %}
{% endfor %}{% endfor %}
{% endfor %}
