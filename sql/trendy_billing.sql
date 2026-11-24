CREATE TABLE IF NOT EXISTS `trendy_invoices` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `issuer` varchar(80) NOT NULL,
  `issuer_name` varchar(100) NOT NULL,
  `recipient` varchar(80) NOT NULL,
  `recipient_name` varchar(100) NOT NULL,
  `society` varchar(80) NOT NULL,
  `job_label` varchar(100) NOT NULL,
  `reason` varchar(120) NOT NULL,
  `amount` int unsigned NOT NULL,
  `status` enum('unpaid','processing','paid') NOT NULL DEFAULT 'unpaid',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `paid_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `recipient_status` (`recipient`,`status`),
  KEY `society` (`society`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
