json._id @item._id
json.created @item.created
json.updated @item.updated
json.ldap_dn @item.ldap_dn
json.name @item.name
json.uid @item.uid
json.email @item.email
json.type @item.type
json.login_roles @item.login_roles
json.last_loggedin @item.last_loggedin
json.group_ids @item.group_ids
json.groups @item.groups.each do |group|
  json._id group._id
  json.name group.name
end
json.sys_role_ids @item.sys_role_ids
json.sys_roles @item.sys_roles.each do |role|
  json._id role._id
  json.name role.name
end
