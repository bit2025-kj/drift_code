from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload
from app.database import get_db
from app.models import EducationLevel, Classe, Matiere, TypeExamen

router = APIRouter(prefix="/education", tags=["Référentiel Éducation"])


@router.get("/levels")
async def get_levels(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(EducationLevel).options(selectinload(EducationLevel.classes)).order_by(EducationLevel.order)
    )
    levels = result.scalars().all()
    return [
        {
            "id": l.id, "name": l.name, "slug": l.slug,
            "icon": l.icon, "color": l.color,
            "classes": [{"id": c.id, "name": c.name, "slug": c.slug} for c in l.classes],
        }
        for l in levels
    ]


@router.get("/matieres")
async def get_matieres(db: AsyncSession = Depends(get_db), classe_id: int | None = None):
    stmt = select(Matiere).order_by(Matiere.name)
    result = await db.execute(stmt)
    matieres = result.scalars().all()
    return [{"id": m.id, "name": m.name, "slug": m.slug, "icon": m.icon, "color": m.color} for m in matieres]


@router.get("/types-examens")
async def get_types_examens(db: AsyncSession = Depends(get_db), level_id: int | None = None):
    stmt = select(TypeExamen).order_by(TypeExamen.order)
    if level_id:
        stmt = stmt.where(TypeExamen.level_id == level_id)
    result = await db.execute(stmt)
    types = result.scalars().all()
    return [
        {"id": t.id, "name": t.name, "slug": t.slug, "is_national": t.is_national}
        for t in types
    ]


@router.get("/classes")
async def get_classes(
    db: AsyncSession = Depends(get_db),
    level_id: int | None = None,
):
    stmt = select(Classe).order_by(Classe.order)
    if level_id:
        stmt = stmt.where(Classe.level_id == level_id)
    result = await db.execute(stmt)
    classes = result.scalars().all()
    return [{"id": c.id, "name": c.name, "slug": c.slug, "level_id": c.level_id, "order": c.order} for c in classes]


@router.get("/annees")
async def get_available_years():
    current_year = 2024
    return list(range(current_year, 2009, -1))
