output "passwords" {
    value = {
        rds_db_password = random_password.rds_db_password.result
    }
    sensitive = true
}