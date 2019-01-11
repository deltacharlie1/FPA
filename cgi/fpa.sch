-- MySQL dump 10.15  Distrib 10.0.22-MariaDB, for Linux (x86_64)
--
-- Host: localhost    Database: fpa3
-- ------------------------------------------------------
-- Server version	10.0.22-MariaDB-log

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `accounts`
--

DROP TABLE IF EXISTS `accounts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `accounts` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `acct_id` varchar(50) NOT NULL DEFAULT '' COMMENT 'reg_id + com_id as in 123+456',
  `acctype` varchar(50) NOT NULL DEFAULT '' COMMENT 'Type of Account, eg current, deposit etc',
  `accshort` varchar(50) NOT NULL DEFAULT '' COMMENT 'Short name for the account type',
  `accname` varchar(250) NOT NULL DEFAULT '' COMMENT 'Name of Account, eg HSBC current Account',
  `accsort` varchar(50) NOT NULL DEFAULT '' COMMENT 'Sort Code',
  `accacctno` varchar(20) NOT NULL DEFAULT '' COMMENT 'Account No',
  `acctswift` varchar(20) NOT NULL DEFAULT '' COMMENT 'Account Swift Code no',
  `old_id` int(10) unsigned DEFAULT NULL,
  `accnewrec` char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  KEY `acct_id` (`acct_id`)
) ENGINE=MyISAM AUTO_INCREMENT=9730 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `add_users`
--

DROP TABLE IF EXISTS `add_users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `add_users` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `addemail` varchar(250) NOT NULL DEFAULT '' COMMENT 'email address of new user',
  `addusername` varchar(250) NOT NULL DEFAULT '' COMMENT ' Name of new user',
  `addactive` char(3) NOT NULL DEFAULT 'P' COMMENT 'Flag to denote whether this has been activated P or C (any Cs can be deleted)',
  `addactivecode` varchar(250) DEFAULT NULL COMMENT 'SHA activation code for Pending additional user',
  `addreg2_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'registration id of original owner',
  `addcom_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'id of company',
  `addcomname` varchar(250) NOT NULL DEFAULT '' COMMENT ' name of company signing on to',
  `old_id` int(10) unsigned DEFAULT NULL,
  `adddate` date DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=10 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `ads2`
--

DROP TABLE IF EXISTS `ads2`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ads2` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `merchant` text,
  `name` text,
  `track` text,
  `thumb` text,
  `image` text,
  `price` text,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=156 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `adverts`
--

DROP TABLE IF EXISTS `adverts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `adverts` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `merchant` text,
  `name` varchar(1000) DEFAULT NULL,
  `track` text,
  `thumb` text,
  `image` text,
  `price` decimal(10,2) NOT NULL DEFAULT '0.00',
  `cat` varchar(30) DEFAULT NULL,
  `grp` int(11) NOT NULL DEFAULT '1',
  `sector` varchar(200) NOT NULL DEFAULT 'all',
  PRIMARY KEY (`id`),
  UNIQUE KEY `adname` (`name`),
  KEY `sort_order` (`grp`)
) ENGINE=MyISAM AUTO_INCREMENT=3725 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `audit_trails`
--

DROP TABLE IF EXISTS `audit_trails`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `audit_trails` (
  `acct_id` varchar(50) NOT NULL DEFAULT '',
  `link_id` int(10) unsigned NOT NULL,
  `audtype` varchar(20) NOT NULL DEFAULT '' COMMENT 'The entity (dataset) that this link_id refers to',
  `audaction` varchar(20) NOT NULL DEFAULT '' COMMENT 'The action refered to, eg print, pay, receive, transfer etc',
  `audstamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `audtext` varchar(250) NOT NULL DEFAULT '',
  `auduser` varchar(50) NOT NULL COMMENT 'userid of user making change',
  `old_id` int(10) unsigned DEFAULT NULL,
  KEY `acct_id` (`acct_id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `categories`
--

DROP TABLE IF EXISTS `categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `categories` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `cat_code` varchar(100) NOT NULL DEFAULT '' COMMENT 'Category Code',
  `cat_description` varchar(255) NOT NULL DEFAULT '' COMMENT 'Category Description',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `coa_txns`
--

DROP TABLE IF EXISTS `coa_txns`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `coa_txns` (
  `acct_id` varchar(50) NOT NULL DEFAULT '',
  `txn_id` int(10) unsigned NOT NULL,
  `ctnominalcode` varchar(10) NOT NULL DEFAULT '',
  `ctamount` decimal(20,2) NOT NULL,
  KEY `ct1` (`acct_id`),
  KEY `ct2` (`txn_id`),
  KEY `ct3` (`ctnominalcode`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `coas`
--

DROP TABLE IF EXISTS `coas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `coas` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `acct_id` varchar(50) NOT NULL DEFAULT '',
  `coanominalcode` char(6) NOT NULL DEFAULT '',
  `coadesc` varchar(250) NOT NULL DEFAULT '' COMMENT 'Description of Nominal Code',
  `coatype` varchar(50) NOT NULL DEFAULT '' COMMENT 'The group to which this code belongs',
  `coagroup` varchar(10) NOT NULL DEFAULT '',
  `coareport` varchar(50) NOT NULL DEFAULT '' COMMENT 'The Report in which this value is reported',
  `coabalance` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT 'The running balance',
  `old_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `acct_id` (`acct_id`)
) ENGINE=MyISAM AUTO_INCREMENT=174906 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `comments`
--

DROP TABLE IF EXISTS `comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `comments` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `comtext` varchar(1000) NOT NULL COMMENT 'reminder text',
  `comuser` varchar(1000) NOT NULL DEFAULT '' COMMENT 'user id of commentator',
  `comgrade` char(1) NOT NULL DEFAULT 'N' COMMENT 'grade of reminder, normal, urgent etc',
  `old_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=38 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `companies`
--

DROP TABLE IF EXISTS `companies`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `companies` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `reg_id` int(10) unsigned DEFAULT NULL COMMENT 'Registration No of this of user registering company',
  `comname` varchar(250) NOT NULL DEFAULT '' COMMENT 'Company Name',
  `comregno` varchar(250) NOT NULL DEFAULT '' COMMENT 'Company Registration No',
  `comaddress` varchar(1000) NOT NULL DEFAULT '' COMMENT 'Address',
  `compostcode` varchar(100) NOT NULL DEFAULT '' COMMENT 'Post Code',
  `comtel` varchar(250) NOT NULL DEFAULT '' COMMENT 'Telephone number',
  `comlogo` blob COMMENT 'Company Logo',
  `combusiness` varchar(250) NOT NULL DEFAULT '' COMMENT 'Type of Business',
  `comcontact` varchar(250) NOT NULL DEFAULT '' COMMENT 'company contact name',
  `comemail` varchar(250) NOT NULL DEFAULT '' COMMENT 'Company email Address',
  `comyearend` varchar(100) NOT NULL DEFAULT '0' COMMENT 'Company Year End month',
  `comnextsi` varchar(80) NOT NULL DEFAULT '100001' COMMENT 'Next Sales Invoice No',
  `comnextpi` varchar(80) NOT NULL DEFAULT '500001' COMMENT 'Next Purchase Invoice No',
  `comnextpr` varchar(80) NOT NULL DEFAULT '1001' COMMENT 'Next Proforma Invoice No',
  `comnexttxn` varchar(80) NOT NULL DEFAULT '1' COMMENT 'Next Transaction Number',
  `comnextjnl` varchar(80) NOT NULL DEFAULT '1',
  `comvatscheme` varchar(10) NOT NULL DEFAULT 'N' COMMENT 'VAT scheme, can be one of N - None, C - Cash, S - Standard',
  `comfrsrate` varchar(5) NOT NULL DEFAULT '20.00',
  `comvatno` varchar(250) NOT NULL DEFAULT '' COMMENT 'Company VAT Registration No',
  `comvatcontrol` decimal(20,2) NOT NULL COMMENT 'VAT control total actually owed to/from HMRC',
  `comvatduein` char(1) NOT NULL DEFAULT '0' COMMENT 'VAT Quarter End',
  `comvatqstart` date NOT NULL DEFAULT '2010-01-01' COMMENT 'Date that quarter starts for next VAT return',
  `comvatmsgdue` date NOT NULL COMMENT 'Date of next VAT reminder message',
  `comnocheques` decimal(5,0) NOT NULL DEFAULT '0' COMMENT 'Total no of cheques currently held',
  `comlastmodified` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Date time record last modified',
  `comyearendmsgdue` date NOT NULL COMMENT 'Date next yearend message due',
  `comyearendreminder` char(1) NOT NULL DEFAULT '' COMMENT 'Reminder flag that year end has not yet been done',
  `comvatreminder` char(1) NOT NULL DEFAULT '' COMMENT 'flag to denote that reminder has been set (is reset once VAT return Filed)',
  `comcompleted` char(1) NOT NULL DEFAULT '' COMMENT 'Flag to denote that Company Setup have been completed',
  `comacccompleted` char(1) NOT NULL COMMENT 'Flag to denote that opening balances have been added',
  `cominvstats` varchar(1000) NOT NULL DEFAULT '' COMMENT 'Field to hold ; delimited monthly invoice stats',
  `comtxnstats` varchar(1000) NOT NULL DEFAULT '' COMMENT 'field to hold ; delimited monthly transaction stats',
  `comnetstats` varchar(1000) NOT NULL DEFAULT '' COMMENT 'field to hold ; delimited monthly net cash flow stats',
  `comoptin` char(1) NOT NULL DEFAULT 'Y' COMMENT 'Flag to denote that the user has opted in to emails',
  `comexpid` int(10) unsigned DEFAULT NULL COMMENT 'id of Expenses /customer/',
  `comemailmsg` varchar(5000) NOT NULL DEFAULT '' COMMENT 'Default email meesage',
  `comstmtmsg` varchar(5000) NOT NULL DEFAULT '' COMMENT 'Default stmt meesage',
  `comdocsdir` varchar(200) NOT NULL DEFAULT '' COMMENT 'Documents directory',
  `comfree` date NOT NULL DEFAULT '2100-01-01' COMMENT 'Access to free system (note extended date)',
  `comno_ads` date NOT NULL DEFAULT '2010-01-01' COMMENT 'Suppress Adverts',
  `comrep_invs` date NOT NULL DEFAULT '2010-01-01' COMMENT 'Allow repeat invoices',
  `comstmts` date NOT NULL DEFAULT '2010-01-01' COMMENT 'Allow Statements',
  `comuplds` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'Remaining Upload capacity',
  `compt_logo` date NOT NULL DEFAULT '2010-01-01' COMMENT 'Allow Logo',
  `comhmrc` date NOT NULL DEFAULT '2010-01-01' COMMENT 'Allow auto-update of HMRC VAT',
  `comsuppt` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'Remaining Support credits',
  `comadd_user` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'number of new users that may be added',
  `old_id` int(10) unsigned DEFAULT NULL,
  `comkeep_recs` date NOT NULL DEFAULT '2010-01-01' COMMENT 'Expiry date for keeping records for 6 years',
  `comadvertise` date NOT NULL DEFAULT '2010-01-01' COMMENT 'Allowed to advertise until this date',
  `comsublevel` char(4) DEFAULT '00',
  `comcis` char(3) NOT NULL DEFAULT 'N',
  `comsubdue` date NOT NULL DEFAULT '2010-01-01',
  `comsubtype` varchar(10) NOT NULL DEFAULT '',
  `comflowsref` varchar(100) NOT NULL DEFAULT '',
  `comcusref` varchar(100) NOT NULL DEFAULT '',
  `commandateref` varchar(100) NOT NULL DEFAULT '',
  `compayref` varchar(100) NOT NULL DEFAULT '',
  `comsubref` varchar(100) NOT NULL DEFAULT '',
  `comlayout` int(11) NOT NULL DEFAULT '0',
  `bkprlevel` char(2) NOT NULL DEFAULT '0',
  `comsoletrader` char(1) NOT NULL DEFAULT 'N',
  `comdougref` varchar(100) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `reg_id` (`reg_id`)
) ENGINE=MyISAM AUTO_INCREMENT=6015 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `customers`
--

DROP TABLE IF EXISTS `customers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `customers` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `acct_id` varchar(50) NOT NULL DEFAULT '',
  `cusname` varchar(250) NOT NULL DEFAULT '' COMMENT 'Customers trading name',
  `cusaddress` varchar(1000) NOT NULL DEFAULT '' COMMENT 'Customers Address',
  `cuspostcode` varchar(100) NOT NULL DEFAULT '',
  `cusregion` varchar(20) NOT NULL DEFAULT '4000' COMMENT 'The VAT region of the customer',
  `custel` varchar(100) NOT NULL DEFAULT '',
  `cuscontact` varchar(250) NOT NULL DEFAULT '' COMMENT 'Customer Contact Name',
  `cusemail` varchar(250) NOT NULL DEFAULT '' COMMENT 'Customer Accounts Email Address',
  `custerms` char(3) NOT NULL DEFAULT '28' COMMENT 'Number of days before payment due',
  `cusdefpo` varchar(100) NOT NULL DEFAULT '' COMMENT 'Customer default Purchase Order No',
  `cusdefcoa` varchar(8) NOT NULL DEFAULT '4000' COMMENT 'Default coa for this customer/supplier',
  `cusdefvatrate` varchar(10) NOT NULL COMMENT 'Default VAT rate',
  `cusbank` varchar(250) NOT NULL DEFAULT '',
  `cussortcode` varchar(20) NOT NULL DEFAULT '',
  `cusacctno` varchar(20) NOT NULL DEFAULT '',
  `cusbalance` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT 'Outstanding balance',
  `cuscredit` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT 'Unallocated Payments',
  `cuslimit` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT 'Any Customer Limit',
  `cusdefpaymethod` varchar(255) NOT NULL DEFAULT '1200' COMMENT 'default method of invoice payment (bank)',
  `cussales` char(1) NOT NULL DEFAULT '' COMMENT 'Flag denoting whether thi customer is a Sales Customer',
  `cussupplier` char(1) NOT NULL DEFAULT '' COMMENT 'Flag denoting whether this customer is a Supplier',
  `cusremarks` varchar(5000) NOT NULL DEFAULT '' COMMENT 'Customer Remarks',
  `cusemailmsg` varchar(5000) NOT NULL DEFAULT '' COMMENT 'Default email meesage for this customer',
  `cusstmtemail` varchar(250) NOT NULL DEFAULT '' COMMENT 'Statement email address (if completed)',
  `cusstmtmsg` varchar(5000) NOT NULL DEFAULT '' COMMENT 'Default stmt meesage for this customer',
  `cusautostmts` char(1) NOT NULL DEFAULT 'N' COMMENT 'Whether to run auto statements for this customer',
  `old_id` int(10) unsigned DEFAULT NULL,
  `cuscis` char(3) NOT NULL DEFAULT 'N',
  `cuslayout` int(11) NOT NULL DEFAULT '0',
  `cusdeliveryaddr` text NOT NULL,
  `cussuppress` char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  KEY `cus1` (`acct_id`),
  KEY `cus2` (`cusname`)
) ENGINE=MyISAM AUTO_INCREMENT=19956 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `gcls`
--

DROP TABLE IF EXISTS `gcls`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gcls` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `acct_id` varchar(50) NOT NULL DEFAULT '',
  `gclflow` varchar(255) NOT NULL DEFAULT '',
  `gclcusid` varchar(200) NOT NULL DEFAULT '',
  `gclmanid` varchar(200) NOT NULL DEFAULT '',
  `gclsubid` varchar(200) NOT NULL DEFAULT '',
  `gclpayid` varchar(200) NOT NULL DEFAULT '',
  `gclsubdate` date DEFAULT NULL,
  `gclpaydate` date DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `gcl1` (`acct_id`),
  KEY `gcl2` (`gclflow`)
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `images`
--

DROP TABLE IF EXISTS `images`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `images` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `link_id` int(10) unsigned NOT NULL COMMENT 'id of associated parent',
  `acct_id` varchar(50) NOT NULL,
  `imgdoc_type` varchar(20) NOT NULL DEFAULT '' COMMENT 'parent type, eg INV,TXN,STMT etc',
  `imgfilename` varchar(50) NOT NULL DEFAULT '' COMMENT ' filename of uploaded file',
  `imgext` varchar(20) NOT NULL DEFAULT '' COMMENT 'extension of file uploaded',
  `imgdesc` text COMMENT 'description of the uploaded document',
  `imgthumb` blob COMMENT 'thumbnail of the image',
  `imgimage` mediumblob COMMENT 'the image, itself',
  `imgdate_saved` date DEFAULT NULL COMMENT 'the date the image was saved',
  `old_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `img1` (`acct_id`),
  KEY `img2` (`link_id`)
) ENGINE=MyISAM AUTO_INCREMENT=24 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `inv_txns`
--

DROP TABLE IF EXISTS `inv_txns`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `inv_txns` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `acct_id` varchar(50) NOT NULL DEFAULT '',
  `txn_id` int(10) unsigned NOT NULL COMMENT 'id of the associated transaction',
  `inv_id` int(10) unsigned NOT NULL COMMENT 'id of invoice',
  `ittxnno` varchar(80) NOT NULL,
  `itinvoiceno` varchar(50) NOT NULL,
  `itnet` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT 'net amount of this transaction element',
  `itvat` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT 'vat amount of this transactio element',
  `itdate` datetime DEFAULT NULL COMMENT 'datetime of the transaction',
  `itmethod` varchar(50) NOT NULL COMMENT 'nominal code of payment method',
  `old_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `itx1` (`acct_id`),
  KEY `itx2` (`txn_id`),
  KEY `itx3` (`inv_id`)
) ENGINE=MyISAM AUTO_INCREMENT=88696 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `invoice_layout_items`
--

DROP TABLE IF EXISTS `invoice_layout_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `invoice_layout_items` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `acct_id` varchar(50) NOT NULL DEFAULT '',
  `link_id` int(10) unsigned DEFAULT NULL,
  `lifldcode` char(8) DEFAULT NULL,
  `lidispname` varchar(30) DEFAULT NULL,
  `litable` varchar(20) DEFAULT NULL,
  `lisource` text,
  `lialias` varchar(20) DEFAULT NULL,
  `litop` char(4) DEFAULT NULL,
  `lileft` char(4) DEFAULT NULL,
  `liwidth` char(3) DEFAULT NULL,
  `lisize` char(2) DEFAULT NULL,
  `libold` char(1) NOT NULL DEFAULT 'N',
  `lidisplay` char(1) NOT NULL DEFAULT 'N',
  `lijust` char(1) NOT NULL DEFAULT 'l',
  PRIMARY KEY (`id`),
  KEY `li1` (`acct_id`)
) ENGINE=MyISAM AUTO_INCREMENT=3160 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `invoice_layouts`
--

DROP TABLE IF EXISTS `invoice_layouts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `invoice_layouts` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `acct_id` varchar(50) NOT NULL DEFAULT '',
  `laydesc` varchar(100) NOT NULL DEFAULT '',
  `laydateformat` varchar(20) NOT NULL DEFAULT '%d-%b-%y',
  `layxoffset` char(3) NOT NULL DEFAULT '830',
  `layyoffset` char(3) NOT NULL DEFAULT '0',
  `layfile` varchar(120) NOT NULL DEFAULT '',
  `descwidth` char(3) NOT NULL DEFAULT '300',
  `descheight` char(3) NOT NULL DEFAULT '300',
  `rmkwidth` char(3) NOT NULL DEFAULT '100',
  `rmkheight` char(3) NOT NULL DEFAULT '60',
  `layreversefile` varchar(120) NOT NULL DEFAULT '',
  `layspace` int(11) NOT NULL DEFAULT '25',
  PRIMARY KEY (`id`),
  KEY `lay1` (`acct_id`)
) ENGINE=MyISAM AUTO_INCREMENT=118 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `invoice_templates`
--

DROP TABLE IF EXISTS `invoice_templates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `invoice_templates` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `acct_id` varchar(50) NOT NULL DEFAULT '',
  `cus_id` int(10) unsigned NOT NULL,
  `invinvoiceno` varchar(50) NOT NULL DEFAULT '',
  `invourref` varchar(250) NOT NULL DEFAULT '' COMMENT 'our ref, used to hold quotation ref',
  `invcusref` varchar(250) NOT NULL DEFAULT '',
  `invtype` char(4) NOT NULL DEFAULT 'S' COMMENT 'S - invoice C - credit Note P - purchase invoice R - Purchase Refund',
  `invcusname` varchar(250) NOT NULL DEFAULT '',
  `invcusaddr` varchar(1000) NOT NULL DEFAULT '',
  `invcuspostcode` varchar(50) NOT NULL DEFAULT '',
  `invcusregion` varchar(20) NOT NULL DEFAULT 'UK',
  `invcuscontact` varchar(250) NOT NULL DEFAULT '',
  `invcusemail` varchar(250) NOT NULL DEFAULT '',
  `invcusterms` varchar(50) NOT NULL DEFAULT '',
  `invremarks` text COMMENT 'Remarks displayed on invoice',
  `invcoa` varchar(20) NOT NULL DEFAULT '4000' COMMENT 'nominalcode  assigned to invoice',
  `invcreated` datetime DEFAULT NULL COMMENT 'Date Invoice first saved',
  `invprintdate` date DEFAULT NULL COMMENT 'Date invoice printed/emailed',
  `invduedate` date DEFAULT NULL COMMENT 'Date payment for the invoice is due',
  `invtotal` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT 'The invoice total (excl VAT if applicable)',
  `invcistotal` decimal(20,2) DEFAULT NULL,
  `invvat` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT 'VAT total',
  `invpaid` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT 'Total paid so far',
  `invpaidvat` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT 'Total VAT paid so far',
  `invpaiddate` date DEFAULT NULL COMMENT 'Date that last instalment was paid',
  `invstatus` varchar(50) NOT NULL DEFAULT 'Draft' COMMENT 'Current Invoice status - Draft, Unpaid, Overdue, Part-Paid, Paid',
  `invstatuscode` decimal(2,0) NOT NULL DEFAULT '0' COMMENT 'Status code, Draft - 1, Printed - 3 etc',
  `invstatusdate` datetime DEFAULT NULL COMMENT 'Status Date',
  `invfpflag` char(1) NOT NULL DEFAULT '' COMMENT 'Flag to denote full payment checkbox checked',
  `invitemcount` int(11) DEFAULT NULL COMMENT 'No of line items',
  `invitems` text COMMENT 'HTML snippet of all line items before invoice saved',
  `invdesc` varchar(250) NOT NULL DEFAULT '' COMMENT 'First line of description',
  `invyearend` varchar(20) NOT NULL DEFAULT '' COMMENT 'Invoice Yearend reporting period',
  `invnotes` text,
  `invlayout` int(11) NOT NULL DEFAULT '0',
  `invrepeatfreq` varchar(20) NOT NULL DEFAULT '7',
  `invnextinv` decimal(6,0) NOT NULL DEFAULT '1' COMMENT ' the number of the next invoice',
  `invlastinv` decimal(6,0) NOT NULL DEFAULT '999999' COMMENT 'the last number, ie max of invoices to be produced',
  `invemailsubj` varchar(100) NOT NULL DEFAULT '' COMMENT 'email subject',
  `invemailmsg` varchar(5000) NOT NULL DEFAULT '' COMMENT 'message to place on email',
  `invemailcopy` varchar(5) NOT NULL DEFAULT 'Y' COMMENT 'copy invoice to self',
  `old_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `invtemp1` (`acct_id`)
) ENGINE=InnoDB AUTO_INCREMENT=74 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `invoices`
--

DROP TABLE IF EXISTS `invoices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `invoices` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `acct_id` varchar(50) NOT NULL DEFAULT '',
  `cus_id` int(10) unsigned NOT NULL,
  `invinvoiceno` varchar(50) NOT NULL DEFAULT '',
  `invourref` varchar(250) NOT NULL DEFAULT '' COMMENT 'our ref, used to hold quotation ref',
  `invcusref` varchar(250) NOT NULL DEFAULT '',
  `invtype` char(4) NOT NULL DEFAULT 'S' COMMENT 'S - invoice C - credit Note P - purchase invoice R - Purchase Refund',
  `invcusname` varchar(250) NOT NULL DEFAULT '',
  `invcusaddr` varchar(1000) NOT NULL DEFAULT '',
  `invcuspostcode` varchar(50) NOT NULL DEFAULT '',
  `invcusregion` varchar(20) NOT NULL DEFAULT 'UK',
  `invcuscontact` varchar(250) NOT NULL DEFAULT '',
  `invcusemail` varchar(250) NOT NULL DEFAULT '',
  `invcusterms` varchar(50) NOT NULL DEFAULT '',
  `invremarks` text COMMENT 'Remarks displayed on invoice',
  `invcoa` varchar(20) NOT NULL DEFAULT '4000' COMMENT 'nominalcode  assigned to invoice',
  `invcreated` datetime DEFAULT NULL COMMENT 'Date Invoice first saved',
  `invprintdate` date DEFAULT NULL COMMENT 'Date invoice printed/emailed',
  `invduedate` date DEFAULT NULL COMMENT 'Date payment for the invoice is due',
  `invtotal` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT 'The invoice total (excl VAT if applicable)',
  `invcistotal` decimal(20,2) DEFAULT NULL,
  `invvat` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT 'VAT total',
  `invpaid` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT 'Total paid so far',
  `invpaidvat` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT 'Total VAT paid so far',
  `invpaiddate` date DEFAULT NULL COMMENT 'Date that last instalment was paid',
  `invstatus` varchar(50) NOT NULL DEFAULT 'Draft' COMMENT 'Current Invoice status - Draft, Unpaid, Overdue, Part-Paid, Paid',
  `invstatuscode` decimal(2,0) NOT NULL DEFAULT '0' COMMENT 'Status code, Draft - 1, Printed - 3 etc',
  `invstatusdate` datetime DEFAULT NULL COMMENT 'Status Date',
  `invfpflag` char(1) NOT NULL DEFAULT '' COMMENT 'Flag to denote full payment checkbox checked',
  `invitemcount` int(11) DEFAULT NULL COMMENT 'No of line items',
  `invitems` text COMMENT 'HTML snippet of all line items before invoice saved',
  `invdesc` varchar(250) NOT NULL DEFAULT '' COMMENT 'First line of description',
  `invyearend` varchar(20) NOT NULL DEFAULT '' COMMENT 'Invoice Yearend reporting period',
  `invrepeat` char(1) NOT NULL DEFAULT '' COMMENT 'flag to denote that this is a repeat invoice',
  `invrepeatfreq` varchar(20) NOT NULL DEFAULT '' COMMENT ' the frequency with which the invoice is to be repeated week, month, year etc',
  `invrepeatnext` date DEFAULT NULL COMMENT 'the date of the next invoice.  This is updated each time the invoice is printed',
  `invaccumstart` decimal(6,0) NOT NULL DEFAULT '0' COMMENT ' the number of the next invoice, only activated if invrepeat = Y',
  `invaccumtot` decimal(6,0) NOT NULL DEFAULT '0' COMMENT 'the last number, ie max of invoices to be produced',
  `invnextinvdate` date NOT NULL DEFAULT '2000-01-01' COMMENT 'Date of next repeat invoice',
  `old_id` int(10) unsigned DEFAULT NULL,
  `invnotes` text,
  `invlayout` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `inv1` (`acct_id`),
  KEY `inv2` (`invinvoiceno`)
) ENGINE=MyISAM AUTO_INCREMENT=105756 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `items`
--

DROP TABLE IF EXISTS `items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `items` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `acct_id` varchar(50) NOT NULL DEFAULT '',
  `inv_id` int(10) unsigned DEFAULT NULL,
  `itminvoiceno` varchar(50) DEFAULT NULL,
  `itmtype` char(1) NOT NULL DEFAULT 'S',
  `itmqty` decimal(8,0) NOT NULL DEFAULT '1',
  `itmnomcode` varchar(20) NOT NULL DEFAULT '',
  `itmdesc` varchar(1000) NOT NULL DEFAULT '',
  `itmtotal` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT 'Total Value excluding any VAT',
  `itmvat` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT 'VAT total',
  `itmvatrate` varchar(50) NOT NULL DEFAULT '' COMMENT 'The VAT rate applied',
  `itmdate` date DEFAULT NULL COMMENT 'Date item created/printed',
  `itmcat` varchar(100) NOT NULL DEFAULT '' COMMENT 'Item Category',
  `old_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `acct_id` (`acct_id`)
) ENGINE=MyISAM AUTO_INCREMENT=131044 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `journals`
--

DROP TABLE IF EXISTS `journals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `journals` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `acct_id` varchar(50) NOT NULL DEFAULT '',
  `joudate` date DEFAULT NULL COMMENT 'journal date',
  `joudesc` text COMMENT 'journal description',
  `joujnlno` char(8) NOT NULL DEFAULT '0',
  `jouacct` varchar(50) NOT NULL DEFAULT '',
  `joutype` varchar(10) NOT NULL DEFAULT '',
  `jouamt` decimal(10,2) NOT NULL DEFAULT '0.00',
  `joucount` smallint(6) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `jou1` (`acct_id`)
) ENGINE=MyISAM AUTO_INCREMENT=272 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `market_sectors`
--

DROP TABLE IF EXISTS `market_sectors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `market_sectors` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `sector` varchar(250) NOT NULL DEFAULT '',
  `frsrate` varchar(5) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=57 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `nominals`
--

DROP TABLE IF EXISTS `nominals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `nominals` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `acct_id` varchar(50) NOT NULL DEFAULT '',
  `link_id` int(10) unsigned NOT NULL COMMENT 'id of root transaction/invoice',
  `journal_id` int(10) unsigned NOT NULL DEFAULT '0',
  `nomtype` char(1) NOT NULL DEFAULT '' COMMENT ' whether link_id is transaction T or invoice I',
  `nomcode` varchar(10) NOT NULL DEFAULT '' COMMENT 'nominal code of this entry',
  `nomgroup` char(10) NOT NULL DEFAULT '',
  `nomamount` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT 'amount for this coa entry',
  `nomdate` date DEFAULT NULL COMMENT 'date of this entry',
  `old_id` int(10) unsigned DEFAULT NULL,
  `nomye` char(1) NOT NULL DEFAULT 'N',
  PRIMARY KEY (`id`),
  KEY `nom1` (`acct_id`),
  KEY `nom2` (`link_id`)
) ENGINE=MyISAM AUTO_INCREMENT=432834 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `poll`
--

DROP TABLE IF EXISTS `poll`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `poll` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `email` text,
  `vote` char(2) DEFAULT NULL,
  `poll` char(20) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=34 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `products`
--

DROP TABLE IF EXISTS `products`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `products` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `acct_id` varchar(50) NOT NULL,
  `prodesc` varchar(120) NOT NULL DEFAULT '' COMMENT 'Description of line item',
  `proprice` decimal(12,2) NOT NULL DEFAULT '0.00' COMMENT 'Default price of line item',
  `procode` varchar(20) NOT NULL DEFAULT '' COMMENT 'Product code',
  `procat` varchar(50) NOT NULL DEFAULT '' COMMENT 'Category of line item',
  `provatrate` varchar(20) NOT NULL DEFAULT 'zero' COMMENT 'the default VAT rate for this item',
  PRIMARY KEY (`id`),
  KEY `prod1` (`acct_id`),
  KEY `prod2` (`procode`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `recpayments`
--

DROP TABLE IF EXISTS `recpayments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `recpayments` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `acct_id` varchar(50) NOT NULL DEFAULT '',
  `reccus_id` int(10) unsigned DEFAULT NULL COMMENT 'supplier id',
  `recnextdate` date DEFAULT NULL COMMENT 'date of next payment',
  `recfreq` varchar(50) NOT NULL DEFAULT '' COMMENT 'mysql text ofr date add - frequency of payments',
  `rectype` varchar(20) NOT NULL DEFAULT '' COMMENT 'type of payment eg DD, SO etc',
  `rectxnmethod` varchar(6) NOT NULL DEFAULT '1200' COMMENT 'which bank account payment comes from',
  `reccoa` varchar(6) NOT NULL DEFAULT '6000' COMMENT 'Expenses cateogory (acct)',
  `recdesc` text COMMENT 'description of payment',
  `recref` text COMMENT 'reference for payment',
  `recamount` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT 'recurring payment amount',
  `recvatrate` char(5) NOT NULL DEFAULT 'Z' COMMENT 'vat rate as a letter (,S,R,Z)',
  PRIMARY KEY (`id`),
  KEY `rec1` (`acct_id`)
) ENGINE=MyISAM AUTO_INCREMENT=72 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `reg_coms`
--

DROP TABLE IF EXISTS `reg_coms`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `reg_coms` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `reg1_id` int(10) unsigned DEFAULT NULL COMMENT 'id of the registrant',
  `reg2_id` int(10) unsigned DEFAULT NULL COMMENT 'registration id of the company, ie who registered the company',
  `com_id` int(10) unsigned DEFAULT NULL COMMENT 'id of the company',
  `comname` varchar(250) NOT NULL DEFAULT '',
  `mlgrate` varchar(20) NOT NULL COMMENT 'Mileage rate in pence used by this user',
  `mlgaccum` varchar(20) NOT NULL COMMENT 'running total of miles claimed for',
  `mlgvattype` varchar(20) NOT NULL COMMENT 'car type, used to calculate the VAT claim',
  `mlgdefmenu` varchar(100) NOT NULL DEFAULT 'dashboard.pl' COMMENT 'Default menu',
  `old_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `reg1` (`reg1_id`),
  KEY `reg2` (`reg2_id`),
  KEY `reg3` (`com_id`)
) ENGINE=MyISAM AUTO_INCREMENT=6035 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `registrations`
--

DROP TABLE IF EXISTS `registrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `registrations` (
  `reg_id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Account Identifier',
  `regusername` varchar(250) NOT NULL DEFAULT '' COMMENT 'Registered Users Name',
  `regcompanyname` varchar(250) NOT NULL DEFAULT '' COMMENT 'Registered Users Company Name',
  `regemail` varchar(250) NOT NULL COMMENT 'Email address, used as long id',
  `regpwd` varchar(50) NOT NULL COMMENT '(Encrypted using password function) Password (6-20 chars)',
  `regmemword` varchar(100) NOT NULL COMMENT 'Memorable word (6-100 chars)',
  `regmembership` varchar(50) NOT NULL DEFAULT '1' COMMENT 'Membership level an array of flags to denote additional options',
  `regactive` char(3) NOT NULL DEFAULT 'P' COMMENT 'Flag to denote whether this account is fully active.  Values are P, C',
  `regactivecode` varchar(250) DEFAULT NULL COMMENT 'SHA activation code for Pending registrations',
  `regregdate` datetime DEFAULT NULL COMMENT 'Date of Initial Registration',
  `regrenewaldue` datetime NOT NULL DEFAULT '2036-12-31 23:59:59' COMMENT 'Running renewal date.  Initially set for Free user',
  `reglastlogindate` datetime DEFAULT NULL COMMENT 'Date of last login.  Used to determine whether this is a dormant account',
  `regvisitcount` int(11) NOT NULL DEFAULT '0' COMMENT 'Count of the number of logins',
  `regcountstartdate` datetime DEFAULT NULL COMMENT 'Date that visit counter was reset',
  `regdefaultmenu` varchar(250) NOT NULL DEFAULT 'dashboard.pl' COMMENT ' The defualt initial screen displayed',
  `regdefaultrows` char(5) NOT NULL DEFAULT '30' COMMENT 'Default number of rows to show for listings',
  `regmenutype` char(1) NOT NULL DEFAULT 'F' COMMENT ' menu type to use - F - Full, S - Simple',
  `regoptin` char(1) NOT NULL DEFAULT 'Y' COMMENT 'opt in flag for emails and newsletter values ar Y/N',
  `old_id` int(10) unsigned DEFAULT NULL,
  `regreferer` varchar(200) NOT NULL DEFAULT '',
  `reglastemail` int(11) DEFAULT '0',
  `regprefs` varchar(200) NOT NULL DEFAULT 'YYNYYY',
  `regmobile` varchar(30) NOT NULL DEFAULT '',
  PRIMARY KEY (`reg_id`),
  UNIQUE KEY `regemail` (`regemail`),
  KEY `regemail_2` (`regemail`)
) ENGINE=MyISAM AUTO_INCREMENT=6002 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `reminders`
--

DROP TABLE IF EXISTS `reminders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `reminders` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `acct_id` varchar(50) NOT NULL,
  `remtext` varchar(1000) NOT NULL COMMENT 'reminder text',
  `remcode` varchar(20) NOT NULL DEFAULT 'GEN' COMMENT 'Grouping code to determine the type ofthe reminder',
  `remgrade` char(1) NOT NULL DEFAULT 'N' COMMENT 'grade of reminder, normal, urgent etc',
  `remstartdate` date DEFAULT NULL COMMENT 'date that reminders is to be displayed',
  `remenddate` date DEFAULT NULL COMMENT 'date that reminder is no longer to be shown and deleted',
  `old_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `acct_id` (`acct_id`)
) ENGINE=MyISAM AUTO_INCREMENT=3276 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `statements`
--

DROP TABLE IF EXISTS `statements`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `statements` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `acct_id` varchar(50) NOT NULL DEFAULT '',
  `acc_id` int(10) unsigned DEFAULT NULL COMMENT 'bank account id',
  `staopenbal` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT 'Bank opening balance',
  `staclosebal` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT 'bank closing balance',
  `stastmtno` varchar(20) DEFAULT NULL,
  `stanotxns` varchar(12) NOT NULL DEFAULT '' COMMENT 'number of transactions on the account',
  `staopendate` datetime DEFAULT NULL COMMENT 'open date of the statement',
  `staclosedate` datetime DEFAULT NULL COMMENT 'close date of the statement',
  `starec_no` int(10) unsigned DEFAULT NULL COMMENT 'The current reconciliation number as a running total',
  `old_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `acct_id` (`acct_id`)
) ENGINE=MyISAM AUTO_INCREMENT=1650 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `subscriptions`
--

DROP TABLE IF EXISTS `subscriptions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `subscriptions` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `acct_id` varchar(50) NOT NULL,
  `subdatepaid` date DEFAULT NULL COMMENT 'date subscription paid',
  `subinvoiceno` int(11) DEFAULT NULL COMMENT 'payment invoice no',
  `subdescription` varchar(120) NOT NULL DEFAULT '' COMMENT 'description of payment',
  `subnet` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT 'Net subscription amount',
  `subvat` decimal(10,2) NOT NULL DEFAULT '0.00' COMMENT 'VAT on subscription',
  `subfee` decimal(10,2) NOT NULL DEFAULT '0.00',
  `subauthcode` varchar(12) NOT NULL DEFAULT '' COMMENT 'Auth Code return by card processor',
  `substatus` varchar(12) NOT NULL DEFAULT '' COMMENT 'Status of payment',
  `submerchantref` varchar(50) DEFAULT NULL COMMENT 'Subscriber Merchantref',
  `subreason` text COMMENT 'reason for rejection/acceptance',
  `subinvtype` char(1) NOT NULL DEFAULT 'I' COMMENT 'whether this is an incoice (I) or refund (R)',
  `subdateraised` date DEFAULT NULL COMMENT 'date invoice raised',
  `subdatpayreceived` date DEFAULT NULL COMMENT 'date payment was received',
  `subpaymentref` varchar(20) NOT NULL DEFAULT '' COMMENT 'reference of payment receipt',
  `subDDIref` varchar(20) NOT NULL DEFAULT '',
  `vatreturn_id` int(11) NOT NULL DEFAULT '0',
  `stmt_id` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `sub1` (`acct_id`)
) ENGINE=MyISAM AUTO_INCREMENT=1494 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `tempstacks`
--

DROP TABLE IF EXISTS `tempstacks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tempstacks` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `acct_id` varchar(50) NOT NULL,
  `caller` varchar(100) NOT NULL COMMENT 'Program associated with this temp table',
  `f1` mediumtext,
  `f2` text,
  `f3` mediumtext,
  `f4` varchar(250) NOT NULL,
  `f5` varchar(250) NOT NULL,
  `f6` varchar(250) NOT NULL,
  `f7` varchar(250) NOT NULL,
  `f8` varchar(250) NOT NULL,
  `f9` varchar(250) NOT NULL,
  `old_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ts1` (`acct_id`),
  KEY `ts2` (`caller`)
) ENGINE=MyISAM AUTO_INCREMENT=12029 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `transactions`
--

DROP TABLE IF EXISTS `transactions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `transactions` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `acct_id` varchar(50) NOT NULL DEFAULT '',
  `link_id` int(10) unsigned DEFAULT NULL,
  `stmt_id` int(10) unsigned DEFAULT NULL,
  `txntxnno` varchar(80) NOT NULL,
  `txnamount` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT 'The net amount of the transaction',
  `txndate` datetime DEFAULT NULL COMMENT 'Date time of the transaction',
  `txnmethod` varchar(20) NOT NULL DEFAULT '' COMMENT 'method of this transaction, ie cash, cheque, transfer, credit card',
  `txnbanked` char(1) NOT NULL DEFAULT '' COMMENT 'flag denoting whether cheque transactions have been banked',
  `txnselected` char(1) NOT NULL DEFAULT '' COMMENT 'flag to denote that this entry has been selected for reconciliation',
  `txntxntype` varchar(50) NOT NULL DEFAULT '' COMMENT 'the type of transaction ie (S)ales, (P)urchase, (B)ank',
  `txncusname` varchar(250) NOT NULL DEFAULT '' COMMENT ' name of the customer making/receiving this transaction',
  `txnremarks` varchar(5000) NOT NULL DEFAULT '' COMMENT 'any remarks to do with this transaction',
  `txnyearend` varchar(20) NOT NULL DEFAULT '' COMMENT 'Transaction yearend reporting period',
  `txncreated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `old_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `acct_id` (`acct_id`)
) ENGINE=MyISAM AUTO_INCREMENT=101389 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `vataccruals`
--

DROP TABLE IF EXISTS `vataccruals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `vataccruals` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vr_id` int(10) unsigned NOT NULL COMMENT 'Vat Return id',
  `acct_id` varchar(50) NOT NULL DEFAULT '',
  `acrtotal` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT 'Total excl VAT',
  `acrvat` decimal(20,2) NOT NULL DEFAULT '0.00' COMMENT 'VAT Amount owed to/by HMRC',
  `acrtype` char(1) NOT NULL DEFAULT '' COMMENT 'Type of accrual, Input or Output',
  `acrquarter` text COMMENT 'the quarter in which the VAT is due (and paid!)',
  `acrprintdate` datetime DEFAULT NULL COMMENT 'date vat became liable',
  `acrnominalcode` varchar(20) NOT NULL DEFAULT '' COMMENT 'Nominal code of this vat txn for Form 100 purposes',
  `acrtxn_id` int(10) unsigned DEFAULT NULL COMMENT 'the id of the relevant transaction record (transaction for Cash accounting, inv_txn for Standard accounting)',
  `acrcreated` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `old_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `acct_id` (`acct_id`)
) ENGINE=MyISAM AUTO_INCREMENT=24626 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `vatperiods`
--

DROP TABLE IF EXISTS `vatperiods`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `vatperiods` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `acct_id` int(11) DEFAULT NULL,
  `perquarter` text,
  `perinputtot` decimal(20,2) DEFAULT NULL,
  `peroutputtot` decimal(20,2) DEFAULT NULL,
  `perclosed` date DEFAULT NULL COMMENT 'Date this quarter was closed',
  `perdateform` date DEFAULT NULL COMMENT 'date VAT form 100 completed',
  `perdatepayment` date DEFAULT NULL COMMENT 'date payment made/received',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `vatrates`
--

DROP TABLE IF EXISTS `vatrates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `vatrates` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `vatcode` char(2) NOT NULL DEFAULT 'S',
  `vatdesc` varchar(50) NOT NULL DEFAULT '' COMMENT 'VAT Rate description eg Standard (2009)',
  `vatpercent` char(8) NOT NULL DEFAULT '20%',
  `vatcalc` decimal(7,3) NOT NULL DEFAULT '0.200' COMMENT 'Value used to calculate tax',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=5 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `vatreturns`
--

DROP TABLE IF EXISTS `vatreturns`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `vatreturns` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `acct_id` varchar(50) NOT NULL DEFAULT '',
  `perquarter` varchar(50) NOT NULL DEFAULT '' COMMENT 'The quater (Q? YYYY) for the return in question',
  `perstartdate` date NOT NULL COMMENT 'Start date for this quarter',
  `perenddate` date NOT NULL COMMENT 'End Date for this quarter',
  `perduedate` date DEFAULT NULL COMMENT 'Date VAT Return is due to HMRC',
  `perstatus` varchar(50) NOT NULL DEFAULT '' COMMENT 'Current Status = open - not completed, closed - completed, filed - filed to HMRC',
  `perstatusdate` datetime DEFAULT NULL,
  `perbox1` decimal(20,2) NOT NULL DEFAULT '0.00',
  `perbox2` decimal(20,2) NOT NULL DEFAULT '0.00',
  `perbox3` decimal(20,2) NOT NULL DEFAULT '0.00',
  `perbox4` decimal(20,2) NOT NULL DEFAULT '0.00',
  `perbox5` decimal(20,2) NOT NULL DEFAULT '0.00',
  `perbox6` decimal(18,0) NOT NULL DEFAULT '0',
  `perbox7` decimal(18,0) NOT NULL DEFAULT '0',
  `perbox8` decimal(18,0) NOT NULL DEFAULT '0',
  `perbox9` decimal(18,0) NOT NULL DEFAULT '0',
  `percompleted` date DEFAULT NULL,
  `perfiled` date DEFAULT NULL,
  `old_id` int(10) unsigned DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `vatr1` (`acct_id`),
  KEY `vatr2` (`perquarter`)
) ENGINE=MyISAM AUTO_INCREMENT=147 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2017-10-23 23:23:34
