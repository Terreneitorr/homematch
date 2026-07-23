from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.models import User, Property, Favorite
from app.database import get_db
from app.auth.dependencies import get_current_user

router = APIRouter()


@router.get("/")
def get_market_analytics(db: Session = Depends(get_db)):
    """
    Estadísticas generales del mercado, usadas por AnalyticsView en la app
    (pantalla "Estadísticas del mercado" en los perfiles de Vendedor/Inmobiliaria).
    """
    total_properties = db.query(Property).count()
    avg_price = db.query(func.avg(Property.price)).scalar() or 0

    city_counts = (
        db.query(Property.city, func.count(Property.id).label("total"))
        .group_by(Property.city)
        .order_by(func.count(Property.id).desc())
        .limit(10)
        .all()
    )
    by_city = [
        {"city": city, "count": count}
        for city, count in city_counts if city
    ]

    op_counts = (
        db.query(Property.operation_type, func.count(Property.id).label("total"))
        .group_by(Property.operation_type)
        .all()
    )
    by_operation_type = [
        {"type": op_type, "count": count}
        for op_type, count in op_counts if op_type
    ]

    return {
        "total_properties": total_properties,
        "average_price": float(avg_price),
        "by_city": by_city,
        "by_operation_type": by_operation_type,
    }


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