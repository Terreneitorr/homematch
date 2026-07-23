from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.models import User, Property, Favorite
from app.database import get_db
from app.auth.dependencies import get_current_user

router = APIRouter()


@router.get("/users-favorites-data")
def get_users_favorites_data(
        db: Session = Depends(get_db),
        current_user: User = Depends(get_current_user)
):
    """
    Devuelve los favoritos de TODOS los usuarios para el filtrado colaborativo
    (el ML los usa para encontrar usuarios con gustos parecidos).

    IMPORTANTE: no se incluye el user_id de cada registro a propósito. El
    algoritmo de recomendación (ver ml-service/app/model/classifier.py,
    build_user_vector y get_collaborative_recommendations) solo necesita la
    lista de propiedades favoritas de cada usuario para calcular similitud
    y popularidad — nunca lee el user_id. Mandarlo sería exponer sin
    necesidad qué usuario específico marcó cada propiedad como favorita.
    """
    users = db.query(User).filter(User.is_active == True).all()
    result = []

    for user in users:
        favs = db.query(Favorite).filter(
            Favorite.user_id == user.id
        ).all()

        fav_properties = []
        for fav in favs:
            prop = db.query(Property).filter(
                Property.id == fav.property_id
            ).first()
            if prop:
                fav_properties.append({
                    "id": prop.id,
                    "price": prop.price,
                    "bedrooms": prop.bedrooms,
                    "bathrooms": prop.bathrooms,
                    "area": prop.area,
                    "title": prop.title,
                    "city": prop.city,
                })

        if fav_properties:
            result.append({
                "favorites": fav_properties,
            })

    return result