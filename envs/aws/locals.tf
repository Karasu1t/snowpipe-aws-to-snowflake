#setup.shの実行結果をXXX/YYYに差し替える
#snowsqlの結果をZZZに差し替える
locals {
  project                 = "karasuit"
  aws_region              = "ap-northeast-1"
  aws_iam_role_principal  = "XXX"
  externalid              = "YYY"
  notification_channel    = "ZZZ"
}
