from app.models.user import User, TeacherProfile
from app.models.education import EducationLevel, Classe, Matiere, TypeExamen, matiere_classe
from app.models.document import Document, DocumentLike, Favorite, Download
from app.models.quiz import Quiz, Question, QuizSession
from app.models.forum import ForumCategory, Discussion, DiscussionComment, DiscussionLike, CommentLike
from app.models.marketplace import Product, Purchase, TeacherRequest
from app.models.badge import Badge, UserBadge
from app.models.chat import ConversationThread, ConversationMessage, ChatDocument
from app.models.notification import Notification

__all__ = [
    "User", "TeacherProfile",
    "EducationLevel", "Classe", "Matiere", "TypeExamen", "matiere_classe",
    "Document", "DocumentLike", "Favorite", "Download",
    "Quiz", "Question", "QuizSession",
    "ForumCategory", "Discussion", "DiscussionComment", "DiscussionLike", "CommentLike",
    "Product", "Purchase", "TeacherRequest",
    "Badge", "UserBadge",
    "ConversationThread", "ConversationMessage", "ChatDocument",
    "Notification",
]
