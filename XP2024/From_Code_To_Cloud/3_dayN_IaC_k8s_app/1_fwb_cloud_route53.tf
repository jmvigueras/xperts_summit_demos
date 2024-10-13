#-----------------------------------------------------------------------------------------------------
# Create new APP in FortiWEB Cloud
#-----------------------------------------------------------------------------------------------------
# Create votes FWEB Cloud APP
data "template_file" "fwb_cloud_votes_app" {
  template = file("./templates/fwb_cloud_new_app.tpl")
  vars = {
    token       = var.fwb_cloud_token
    region      = local.fortiweb_region["aws"]
    app_name    = "votes"
    zone_name   = local.route53_zone_name
    server_ip   = local.fgt_values["aws"]["PUBLIC_IP"]
    server_port = local.votes_nodeport
    template_id = local.fwb_cloud_template
    file_name   = "app_votes_cname_record.txt"
    platform    = local.fortiweb_platform["aws"]
  }
}
# Launch command to create APP
resource "null_resource" "fwb_cloud_votes_app" {
  provisioner "local-exec" {
    command = data.template_file.fwb_cloud_votes_app.rendered
  }
}
# Create results FWEB Cloud APP
data "template_file" "fwb_cloud_results_app" {
  template = file("./templates/fwb_cloud_new_app.tpl")
  vars = {
    token       = var.fwb_cloud_token
    region      = local.fortiweb_region["aws"]
    app_name    = "results"
    zone_name   = local.route53_zone_name
    server_ip   = local.fgt_values["aws"]["PUBLIC_IP"]
    server_port = local.results_nodeport
    template_id = local.fwb_cloud_template
    file_name   = "app_results_cname_record.txt"
    platform    = local.fortiweb_platform["aws"]
  }
}
# Launch command
resource "null_resource" "fwb_cloud_results_app" {
  depends_on = [ null_resource.fwb_cloud_votes_app ]
  provisioner "local-exec" {
    command = data.template_file.fwb_cloud_results_app.rendered
  }
}
#-----------------------------------------------------------------------------------------------------
# Create new Route53 record
#-----------------------------------------------------------------------------------------------------
# Read Route53 Zone info
data "aws_route53_zone" "route53_zone" {
  name         = "${local.route53_zone_name}."
  private_zone = false
}
# Read FortiWEB new APP CNAME file after FWB Cloud command be applied
data "local_file" "fwb_cloud_votes_cname" {
  depends_on = [null_resource.fwb_cloud_votes_app]
  filename   = "app_votes_cname_record.txt"
}
data "local_file" "fwb_cloud_results_cname" {
  depends_on = [null_resource.fwb_cloud_results_app]
  filename   = "app_results_cname_record.txt"
}
# Create Route53 record entry with FWB APP CNAME
resource "aws_route53_record" "votes_record_type_cname" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = "votes.${data.aws_route53_zone.route53_zone.name}"
  type    = "CNAME"
  ttl     = "30"
  records = [data.local_file.fwb_cloud_votes_cname.content]
}
# Create Route53 record entry with FWB APP CNAME
resource "aws_route53_record" "results_record_type_cname" {
  zone_id = data.aws_route53_zone.route53_zone.zone_id
  name    = "results.${data.aws_route53_zone.route53_zone.name}"
  type    = "CNAME"
  ttl     = "30"
  records = [data.local_file.fwb_cloud_results_cname.content]
}