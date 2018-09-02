<div id="content">
    <h3>Welcome to Nekonote Framework!</h3>
    <p class="description">{{description}}</p>

    <h4>Environments</h4>
    <ul>
        <li>The version is <em>{{version}}</em></li>
        <li>Current Environment: <em>{{env}}</em></li>
        <li>The Application Root: <em>{{root}}</em></li>
    </ul>

    <h4>Do you need help?</h4>
    <ul>
        <li>Reference Manual <a target="_blank" href="{% setting_get url, document %}">{% setting_get url, document %}</a></li>
        <li>Contribute <a target="_blank" href="{% setting_get url, contribute %}">{% setting_get url, contribute %}</a></li>
        <li>Changelog <a target="_blank" href="{% setting_get url, changelog %}">{% setting_get url, changelog %}</a></li>
    </ul>

    <h4>Nekonote Framework is open-source software</h4>
    <ul>
        <li>License <a target="_blank" href="{% setting_get url, license %}">{% setting_get url, license %}</a></li>
        <li>GitHub <a target="_blank" href="{% setting_get url, github %}">{% setting_get url, github %}</a></li>
        <li>Repository <a target="_blank" href="{% setting_get url, gem %}">{% setting_get url, gem %}</a></li>
    </ul>

    <div id="footer-logo"></div>
</div>
