CREATE DATABASE IF NOT EXISTS `your_ecommerce_database`
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE `your_ecommerce_database`;

-- Sessão (opcional, mas bom para garantir)
SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;
SET time_zone = '-03:00'; -- Ajuste para seu fuso horário se necessário

-- Módulo Usuários, Perfis e Permissões (Base)
CREATE TABLE IF NOT EXISTS `users` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(255) NOT NULL,
  `email` VARCHAR(255) NOT NULL UNIQUE,
  `email_verified_at` TIMESTAMP NULL,
  `password` VARCHAR(255) NOT NULL COMMENT 'HASH seguro da senha',
  `remember_token` VARCHAR(100) NULL,
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_users_email` (`email`),
  INDEX `idx_users_is_active` (`is_active`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `roles` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(50) NOT NULL UNIQUE COMMENT 'Ex: admin, customer, editor',
  `description` VARCHAR(255) NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_roles_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `permissions` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL UNIQUE COMMENT 'Identificador da permissão (ex: products.create)',
  `description` VARCHAR(255) NULL,
  `group_name` VARCHAR(50) NULL COMMENT 'Agrupamento para UI (ex: Produtos)',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_permissions_name` (`name`),
  INDEX `idx_permissions_group_name` (`group_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `user_roles` (
  `user_id` INT UNSIGNED NOT NULL,
  `role_id` INT UNSIGNED NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`, `role_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `role_permissions` (
  `role_id` INT UNSIGNED NOT NULL,
  `permission_id` INT UNSIGNED NOT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`role_id`, `permission_id`),
  FOREIGN KEY (`role_id`) REFERENCES `roles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (`permission_id`) REFERENCES `permissions` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `addresses` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NOT NULL,
  `recipient_name` VARCHAR(255) NULL,
  `address_line_1` VARCHAR(255) NOT NULL,
  `address_line_2` VARCHAR(255) NULL,
  `city` VARCHAR(100) NOT NULL,
  `state` VARCHAR(100) NOT NULL,
  `postal_code` VARCHAR(20) NOT NULL,
  `country` VARCHAR(100) NOT NULL,
  `phone_number` VARCHAR(50) NULL,
  `address_type` ENUM('shipping', 'billing', 'other') NOT NULL DEFAULT 'other',
  `is_default_shipping` BOOLEAN NOT NULL DEFAULT FALSE,
  `is_default_billing` BOOLEAN NOT NULL DEFAULT FALSE,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX `idx_addresses_user_id` (`user_id`),
  INDEX `idx_addresses_postal_code` (`postal_code`),
  INDEX `idx_addresses_type` (`address_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `password_resets` (
  `email` VARCHAR(255) NOT NULL PRIMARY KEY,
  `token` VARCHAR(255) NOT NULL UNIQUE COMMENT 'HASH do token seguro',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX `idx_password_resets_created_at` (`created_at`) -- PK já indexa email, token UNIQUE já cria índice
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Módulo Catálogo de Produtos (Base)
CREATE TABLE IF NOT EXISTS `categories` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `parent_id` INT UNSIGNED NULL,
  `name` VARCHAR(255) NOT NULL,
  `slug` VARCHAR(255) NOT NULL UNIQUE COMMENT 'URL amigável',
  `description` TEXT NULL,
  `image_url` VARCHAR(255) NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`parent_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  INDEX `idx_categories_slug` (`slug`),
  INDEX `idx_categories_parent_id` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `tags` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `slug` VARCHAR(100) NOT NULL UNIQUE COMMENT 'URL amigável',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_tags_slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `attributes` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL COMMENT 'Ex: Cor, Tamanho',
  `slug` VARCHAR(100) NOT NULL UNIQUE COMMENT 'Ex: cor, tamanho',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_attributes_slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `attribute_values` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `attribute_id` INT UNSIGNED NOT NULL COMMENT 'FK para attributes.id',
  `value` VARCHAR(100) NOT NULL COMMENT 'Ex: Azul, M, 32GB',
  `slug` VARCHAR(100) NULL UNIQUE COMMENT 'Ex: azul, m, 32gb (Opcional)',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`attribute_id`) REFERENCES `attributes` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX `idx_attribute_values_attribute_id` (`attribute_id`),
  INDEX `idx_attribute_values_slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `products` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `sku` VARCHAR(100) UNIQUE NULL COMMENT 'SKU principal',
  `name` VARCHAR(255) NOT NULL,
  `slug` VARCHAR(255) NOT NULL UNIQUE COMMENT 'URL amigável',
  `description` LONGTEXT NULL,
  `short_description` TEXT NULL,
  `price` DECIMAL(10, 2) UNSIGNED NOT NULL DEFAULT 0.00,
  `sale_price` DECIMAL(10, 2) UNSIGNED NULL,
  `sale_start_date` DATETIME NULL,
  `sale_end_date` DATETIME NULL,
  `is_digital` BOOLEAN NOT NULL DEFAULT FALSE,
  `manage_stock` BOOLEAN NOT NULL DEFAULT FALSE,
  `stock_quantity` INT UNSIGNED NULL,
  `stock_status` ENUM('in_stock', 'out_of_stock', 'on_backorder') NOT NULL DEFAULT 'in_stock',
  `weight` DECIMAL(8, 3) UNSIGNED NULL COMMENT 'Peso em Kg',
  `length` DECIMAL(8, 2) UNSIGNED NULL COMMENT 'Comprimento em cm',
  `width` DECIMAL(8, 2) UNSIGNED NULL COMMENT 'Largura em cm',
  `height` DECIMAL(8, 2) UNSIGNED NULL COMMENT 'Altura em cm',
  `is_published` BOOLEAN NOT NULL DEFAULT FALSE,
  `is_featured` BOOLEAN NOT NULL DEFAULT FALSE,
  `product_type` ENUM('simple', 'variable') NOT NULL DEFAULT 'simple',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_products_sku` (`sku`),
  INDEX `idx_products_slug` (`slug`),
  INDEX `idx_products_is_digital` (`is_digital`),
  INDEX `idx_products_stock_status` (`stock_status`),
  INDEX `idx_products_is_published` (`is_published`),
  INDEX `idx_products_is_featured` (`is_featured`),
  INDEX `idx_products_product_type` (`product_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `product_categories` (
  `product_id` INT UNSIGNED NOT NULL,
  `category_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`product_id`, `category_id`),
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `product_tags` (
  `product_id` INT UNSIGNED NOT NULL,
  `tag_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`product_id`, `tag_id`),
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (`tag_id`) REFERENCES `tags` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `product_images` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `product_id` INT UNSIGNED NOT NULL,
  `image_url` VARCHAR(255) NOT NULL,
  `alt_text` VARCHAR(255) NULL,
  `sort_order` INT UNSIGNED NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX `idx_product_images_product_id` (`product_id`),
  INDEX `idx_product_images_sort_order` (`sort_order`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `downloadable_files` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `product_id` INT UNSIGNED NOT NULL COMMENT 'FK para products.id (onde is_digital=TRUE)',
  `name` VARCHAR(255) NOT NULL COMMENT 'Nome amigável do arquivo',
  `file_url_or_path` VARCHAR(1024) NOT NULL COMMENT 'Caminho/ID seguro para o arquivo',
  `file_type` VARCHAR(100) NULL COMMENT 'MIME Type',
  `version` VARCHAR(50) NULL,
  `sort_order` INT UNSIGNED NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX `idx_downloadable_files_product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `product_variations` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `product_id` INT UNSIGNED NOT NULL COMMENT 'FK para products.id (onde type=variable)',
  `sku` VARCHAR(100) UNIQUE NULL COMMENT 'SKU específico da variação',
  `price` DECIMAL(10, 2) UNSIGNED NULL COMMENT 'Preço (se diferente do pai)',
  `sale_price` DECIMAL(10, 2) UNSIGNED NULL,
  `sale_start_date` DATETIME NULL,
  `sale_end_date` DATETIME NULL,
  `manage_stock` BOOLEAN NOT NULL DEFAULT FALSE,
  `stock_quantity` INT UNSIGNED NULL,
  `stock_status` ENUM('in_stock', 'out_of_stock', 'on_backorder') NOT NULL DEFAULT 'in_stock',
  `weight` DECIMAL(8, 3) UNSIGNED NULL,
  `length` DECIMAL(8, 2) UNSIGNED NULL,
  `width` DECIMAL(8, 2) UNSIGNED NULL,
  `height` DECIMAL(8, 2) UNSIGNED NULL,
  `image_id` INT UNSIGNED NULL COMMENT 'FK para product_images.id (opcional)',
  `description` TEXT NULL,
  `is_enabled` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (`image_id`) REFERENCES `product_images` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  INDEX `idx_product_variations_product_id` (`product_id`),
  INDEX `idx_product_variations_sku` (`sku`),
  INDEX `idx_product_variations_stock_status` (`stock_status`),
  INDEX `idx_product_variations_is_enabled` (`is_enabled`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `variation_attribute_values` (
  `variation_id` INT UNSIGNED NOT NULL,
  `attribute_value_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`variation_id`, `attribute_value_id`),
  FOREIGN KEY (`variation_id`) REFERENCES `product_variations` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (`attribute_value_id`) REFERENCES `attribute_values` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Módulo Pedidos
CREATE TABLE IF NOT EXISTS `orders` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT UNSIGNED NULL,
  `guest_email` VARCHAR(255) NULL,
  `order_number` VARCHAR(50) NOT NULL UNIQUE,
  `status` ENUM('pending_payment', 'processing', 'shipped', 'delivered', 'completed', 'cancelled', 'refunded', 'failed') NOT NULL DEFAULT 'pending_payment',
  `currency` CHAR(3) NOT NULL DEFAULT 'BRL',
  `subtotal_amount` DECIMAL(12, 2) UNSIGNED NOT NULL DEFAULT 0.00,
  `discount_amount` DECIMAL(12, 2) UNSIGNED NOT NULL DEFAULT 0.00,
  `coupon_code` VARCHAR(50) NULL,
  `shipping_amount` DECIMAL(12, 2) UNSIGNED NOT NULL DEFAULT 0.00,
  `shipping_method_name` VARCHAR(100) NULL,
  `shipping_tracking_code` VARCHAR(100) NULL,
  `tax_amount` DECIMAL(12, 2) UNSIGNED NOT NULL DEFAULT 0.00,
  `total_amount` DECIMAL(12, 2) UNSIGNED NOT NULL DEFAULT 0.00,
  `billing_recipient_name` VARCHAR(255) NULL,
  `billing_address_line_1` VARCHAR(255) NULL,
  `billing_address_line_2` VARCHAR(255) NULL,
  `billing_city` VARCHAR(100) NULL,
  `billing_state` VARCHAR(100) NULL,
  `billing_postal_code` VARCHAR(20) NULL,
  `billing_country` VARCHAR(100) NULL,
  `billing_phone` VARCHAR(50) NULL,
  `billing_email` VARCHAR(255) NULL,
  `shipping_recipient_name` VARCHAR(255) NULL,
  `shipping_address_line_1` VARCHAR(255) NULL,
  `shipping_address_line_2` VARCHAR(255) NULL,
  `shipping_city` VARCHAR(100) NULL,
  `shipping_state` VARCHAR(100) NULL,
  `shipping_postal_code` VARCHAR(20) NULL,
  `shipping_country` VARCHAR(100) NULL,
  `shipping_phone` VARCHAR(50) NULL,
  `customer_notes` TEXT NULL,
  `admin_notes` TEXT NULL,
  `placed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `paid_at` TIMESTAMP NULL,
  `shipped_at` TIMESTAMP NULL,
  `delivered_at` TIMESTAMP NULL,
  `cancelled_at` TIMESTAMP NULL,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  INDEX `idx_orders_user_id` (`user_id`),
  INDEX `idx_orders_guest_email` (`guest_email`),
  INDEX `idx_orders_order_number` (`order_number`),
  INDEX `idx_orders_status` (`status`),
  INDEX `idx_orders_placed_at` (`placed_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `order_items` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `order_id` INT UNSIGNED NOT NULL,
  `product_id` INT UNSIGNED NOT NULL,
  `variation_id` INT UNSIGNED NULL,
  `product_name` VARCHAR(255) NOT NULL COMMENT 'Snapshot do nome do produto',
  `product_sku` VARCHAR(100) NULL COMMENT 'Snapshot do SKU',
  `quantity` INT UNSIGNED NOT NULL DEFAULT 1,
  `unit_price` DECIMAL(10, 2) UNSIGNED NOT NULL COMMENT 'Preço unitário no momento da compra',
  `total_price` DECIMAL(12, 2) UNSIGNED NOT NULL,
  `attributes_snapshot` JSON NULL COMMENT 'Snapshot dos atributos selecionados',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (`variation_id`) REFERENCES `product_variations` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX `idx_order_items_order_id` (`order_id`),
  INDEX `idx_order_items_product_id` (`product_id`),
  INDEX `idx_order_items_variation_id` (`variation_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `order_payments` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `order_id` INT UNSIGNED NOT NULL,
  `payment_method_slug` VARCHAR(100) NOT NULL COMMENT 'Identificador do método (ex: credit_card)',
  `payment_method_title` VARCHAR(255) NULL COMMENT 'Nome amigável do método',
  `gateway_name` VARCHAR(100) NULL,
  `transaction_id` VARCHAR(255) UNIQUE NULL COMMENT 'ID da transação do gateway',
  `amount` DECIMAL(12, 2) UNSIGNED NOT NULL,
  `currency` CHAR(3) NOT NULL DEFAULT 'BRL',
  `status` ENUM('pending', 'succeeded', 'failed', 'refunded', 'partially_refunded', 'chargeback') NOT NULL DEFAULT 'pending',
  `gateway_response_data` TEXT NULL,
  `paid_at` TIMESTAMP NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX `idx_order_payments_order_id` (`order_id`),
  INDEX `idx_order_payments_transaction_id` (`transaction_id`),
  INDEX `idx_order_payments_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Módulo Blog
CREATE TABLE IF NOT EXISTS `blog_categories` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `parent_id` INT UNSIGNED NULL,
  `name` VARCHAR(255) NOT NULL,
  `slug` VARCHAR(255) NOT NULL UNIQUE,
  `description` TEXT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`parent_id`) REFERENCES `blog_categories` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  INDEX `idx_blog_categories_slug` (`slug`),
  INDEX `idx_blog_categories_parent_id` (`parent_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `blog_tags` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `slug` VARCHAR(100) NOT NULL UNIQUE,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX `idx_blog_tags_slug` (`slug`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `blog_posts` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `author_id` INT UNSIGNED NOT NULL,
  `title` VARCHAR(255) NOT NULL,
  `slug` VARCHAR(255) NOT NULL UNIQUE,
  `excerpt` TEXT NULL,
  `content` LONGTEXT NOT NULL,
  `featured_image_url` VARCHAR(255) NULL,
  `status` ENUM('draft', 'published', 'pending_review', 'scheduled', 'private', 'trash') NOT NULL DEFAULT 'draft',
  `published_at` TIMESTAMP NULL,
  `allow_comments` BOOLEAN NOT NULL DEFAULT TRUE,
  `meta_title` VARCHAR(255) NULL,
  `meta_description` TEXT NULL,
  `views_count` INT UNSIGNED NOT NULL DEFAULT 0,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`author_id`) REFERENCES `users` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX `idx_blog_posts_author_id` (`author_id`),
  INDEX `idx_blog_posts_slug` (`slug`),
  INDEX `idx_blog_posts_status` (`status`),
  INDEX `idx_blog_posts_published_at` (`published_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `blog_post_categories` (
  `blog_post_id` INT UNSIGNED NOT NULL,
  `blog_category_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`blog_post_id`, `blog_category_id`),
  FOREIGN KEY (`blog_post_id`) REFERENCES `blog_posts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (`blog_category_id`) REFERENCES `blog_categories` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `blog_post_tags` (
  `blog_post_id` INT UNSIGNED NOT NULL,
  `blog_tag_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`blog_post_id`, `blog_tag_id`),
  FOREIGN KEY (`blog_post_id`) REFERENCES `blog_posts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (`blog_tag_id`) REFERENCES `blog_tags` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `blog_comments` (
  `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `blog_post_id` INT UNSIGNED NOT NULL,
  `user_id` INT UNSIGNED NULL,
  `parent_id` INT UNSIGNED NULL,
  `author_name` VARCHAR(255) NOT NULL,
  `author_email` VARCHAR(255) NOT NULL,
  `author_website` VARCHAR(255) NULL,
  `content` TEXT NOT NULL,
  `status` ENUM('pending_approval', 'approved', 'spam', 'trash') NOT NULL DEFAULT 'pending_approval',
  `ip_address` VARCHAR(45) NULL,
  `user_agent` VARCHAR(255) NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (`blog_post_id`) REFERENCES `blog_posts` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (`parent_id`) REFERENCES `blog_comments` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  INDEX `idx_blog_comments_blog_post_id` (`blog_post_id`),
  INDEX `idx_blog_comments_user_id` (`user_id`),
  INDEX `idx_blog_comments_parent_id` (`parent_id`),
  INDEX `idx_blog_comments_status` (`status`),
  INDEX `idx_blog_comments_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela para Customer Downloads (conforme discutido para produtos digitais)
-- Esta tabela conecta o item do pedido ao arquivo baixável específico e ao cliente
CREATE TABLE IF NOT EXISTS `customer_downloads` (
    `id` BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `order_item_id` INT UNSIGNED NOT NULL COMMENT 'FK para order_items.id, o item específico que concedeu o acesso',
    `customer_id` INT UNSIGNED NOT NULL COMMENT 'FK para users.id, o cliente que comprou',
    `downloadable_file_id` INT UNSIGNED NOT NULL COMMENT 'FK para downloadable_files.id, o arquivo específico',
    `download_token` VARCHAR(255) UNIQUE NULL COMMENT 'Token seguro e temporário para acesso ao link de download',
    `access_granted_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Quando o acesso foi liberado',
    `download_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Quantas vezes o arquivo foi baixado',
    `download_limit` INT UNSIGNED NULL COMMENT 'Limite de downloads (NULL = ilimitado)',
    `access_expires_at` DATETIME NULL COMMENT 'Quando o acesso ao download expira (NULL = nunca)',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (`order_item_id`) REFERENCES `order_items` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (`customer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE, -- Se o user for deletado, o acesso ao download também some
    FOREIGN KEY (`downloadable_file_id`) REFERENCES `downloadable_files` (`id`) ON DELETE CASCADE ON UPDATE CASCADE, -- Se o arquivo for deletado, o acesso também some
    INDEX `idx_customer_downloads_order_item_id` (`order_item_id`),
    INDEX `idx_customer_downloads_customer_id` (`customer_id`),
    INDEX `idx_customer_downloads_downloadable_file_id` (`downloadable_file_id`),
    INDEX `idx_customer_downloads_download_token` (`download_token`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Fim do script