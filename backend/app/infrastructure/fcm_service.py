import firebase_admin
from firebase_admin import credentials, messaging
import os
import logging

logger = logging.getLogger(__name__)

# Inicializar Firebase Admin solo una vez
_initialized = False

def init_firebase():
    global _initialized
    if _initialized:
        return

    cred_path = os.getenv(
        "FIREBASE_CREDENTIALS_PATH",
        "/app/firebase-credentials.json"
    )

    try:
        if os.path.exists(cred_path) and os.path.isfile(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            _initialized = True
            print(f"[FCM] Firebase Admin inicializado correctamente usando {cred_path}")
            logger.info("[FCM] Firebase Admin inicializado")
        else:
            print(f"[FCM] Error: No se encontró un archivo válido en {cred_path}")
            logger.warning(f"[FCM] No se encontró un archivo válido en {cred_path}")
    except Exception as e:
        print(f"[FCM] Error crítico al inicializar Firebase: {e}")
        logger.error(f"[FCM] Error crítico al inicializar Firebase: {e}")


def is_firebase_initialized():
    return _initialized


class FCMService:

    @staticmethod
    def send_to_token(
            token: str,
            title: str,
            body: str,
            data: dict = None,
    ) -> bool:
        """Envía push notification a un token específico"""
        try:
            message = messaging.Message(
                notification=messaging.Notification(
                    title=title,
                    body=body,
                ),
                data={k: str(v) for k, v in (data or {}).items()},
                token=token,
                android=messaging.AndroidConfig(
                    priority="high",
                    notification=messaging.AndroidNotification(
                        sound="default",
                        click_action="FLUTTER_NOTIFICATION_CLICK",
                    ),
                ),
                apns=messaging.APNSConfig(
                    payload=messaging.APNSPayload(
                        aps=messaging.Aps(sound="default"),
                    ),
                ),
            )
            response = messaging.send(message)
            logger.info(f"[FCM] Enviado: {response}")
            return True
        except Exception as e:
            logger.error(f"[FCM] Error: {e}")
            return False

    @staticmethod
    def send_remote_wipe(token: str, user_id: str) -> bool:
        """Envía comando de wipe remoto"""
        return FCMService.send_to_token(
            token=token,
            title="Alerta de seguridad",
            body="Se ha iniciado una limpieza remota de seguridad.",
            data={
                "action": "REMOTE_WIPE",
                "user_id": user_id,
            },
        )

    @staticmethod
    def send_appointment_notification(
            token: str,
            appointment_type: str,
            scheduled_at: str,
            is_seller: bool = False,
    ) -> bool:
        if is_seller:
            title = "Nueva solicitud de visita"
            body = f"Tienes una nueva solicitud de visita {appointment_type}"
        else:
            title = "Cita agendada ✓"
            body = f"Tu visita {appointment_type} ha sido agendada"

        return FCMService.send_to_token(
            token=token,
            title=title,
            body=body,
            data={
                "action": "OPEN_APPOINTMENTS",
                "type": "appointment",
            },
        )

    @staticmethod
    def send_new_message_notification(
            token: str,
            sender_name: str,
            message_preview: str,
            conversation_id: str,
    ) -> bool:
        return FCMService.send_to_token(
            token=token,
            title=f"Mensaje de {sender_name}",
            body=message_preview[:100],
            data={
                "action": "OPEN_CHAT",
                "conversation_id": conversation_id,
                "type": "message",
            },
        )