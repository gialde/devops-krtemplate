"""Валидатор пользовательских данных."""


def validate_email(email: str) -> bool:
    """Проверяет корректность email-адреса.

    Простая проверка: наличие символа @ и точки после него.
    """
    if not isinstance(email, str):
        return False
    if "@" not in email:
        return False
    local, _, domain = email.partition("@")
    if not local or not domain:
        return False
    if "." not in domain:
        return False
    return True