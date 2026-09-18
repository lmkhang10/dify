# Tables: handbook_articles, handbook_categories

Sổ tay nội bộ. Không query handbook_keywords, handbook_article_keyword, handbook_article_edits, handbook_documents, handbook_settings.

## handbook_categories

- id, organization_id, parent_id, name, slug, icon, description, sort_order, is_active, created_at, updated_at

## handbook_articles

- id, organization_id
- category_id (FK handbook_categories)
- title, slug, summary
- content (longtext — chỉ SELECT khi user cần nội dung bài)
- created_by, updated_by
- is_template (tinyint)
- status (varchar, default draft)
- review_note
- published_at, published_by
- created_at, updated_at
- deleted_at — luôn `deleted_at IS NULL`

Sample:
SELECT a.id, a.title, a.status, a.published_at, c.name AS category_name
FROM handbook_articles a
INNER JOIN handbook_categories c ON c.id = a.category_id
WHERE a.deleted_at IS NULL AND a.status = 'published'
LIMIT 100
