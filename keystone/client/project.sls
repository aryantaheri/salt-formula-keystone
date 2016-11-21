{%- from "keystone/map.jinja" import client with context %}
{%- from "keystone/map.jinja" import keystone_settings with context %}
{%- if client.enabled %}

{%- if client.tenant is defined %}

keystone_salt_config:
  file.managed:
    - name: /etc/salt/minion.d/keystone.conf
    - template: jinja
    - source: salt://keystone/files/salt-minion.conf
    - mode: 600

keystone_client_roles:
  keystone.role_present:
  - names: {{ client.roles }}
  {%- if keystone_settings.token is defined %}
  - connection_token: {{ keystone_settings.token }}
  - connection_endpoint: {{ keystone_settings.endpoint }}
  {%- else %}
  - connection_user: {{ keystone_settings.user }}
  - connection_password: {{ keystone_settings.password }}
  - connection_tenant: {{ keystone_settings.tenant }}
  - connection_auth_url: {{ keystone_settings.auth_url }}
  {%- endif %}
  - require:
    - file: keystone_salt_config

{%- for tenant_name, tenant in client.get('tenant', {}).iteritems() %}

keystone_tenant_{{ tenant_name }}:
  keystone.tenant_present:
  - name: {{ tenant_name }}
  - use:
      - keystone: keystone_client_roles
  - require:
    - keystone: keystone_client_roles

{%- for user_name, user in tenant.get('user', {}).iteritems() %}

keystone_{{ tenant_name }}_user_{{ user_name }}:
  keystone.user_present:
  - name: {{ user_name }}
  - password: {{ user.password }}
  - email: {{ user.get('email', 'root@localhost') }}
  - tenant: {{ tenant_name }}
  - roles:
      "{{ tenant_name }}":
        {%- if user.get('is_admin', False) %}
        - admin
        {%- elif user.get('roles', False) %}
        {{ user.roles }}
        {%- else %}
        - Member
        {%- endif %}
  - use:
      - keystone: keystone_client_roles
  - require:
    - keystone: keystone_tenant_{{ tenant_name }}

{%- endfor %}

{%- endfor %}

{%- endif %}

{%- endif %}
