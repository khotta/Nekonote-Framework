<!DOCTYPE html>
<head>
    <meta charset="UTF-8" />
    <link rel="stylesheet" type="text/css" href="/css/layout/common.css?1.0.0" />
    <link rel="stylesheet" type="text/css" href="/css/layout/default.css?1.0.0" />
    {% if css %}<link rel="stylesheet" type="text/css" href="{{css}}" />{% endif %}
    {% if title %}<title>{{title}}</title>{% endif %}
</head>
<body>
  <div id="header-line"></div>

  <div id="content">
    {{content}}
  </div>
{% comment %}
Note: {{content}} is magical. Your template is rendered there.
{% endcomment %}
</body>
</html>
