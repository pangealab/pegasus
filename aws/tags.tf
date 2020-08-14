//  Wherever possible, we will use a common set of tags for resources. This
//  makes it much easier to set up resource based billing, tag based access,
//  resource groups and more.
locals {
  common_tags = map(
    "Project", "rancher",
  )
}