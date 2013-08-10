#!/usr/bin/perl

#  script to confirm registration of a new client

use Template;

use DBI;
$dbh = DBI->connect("DBI:mysql:fpa");

#  First let's see if this activation code matches what we have in registrations

$Regs = $dbh->prepare("select reg_id,regusername,regemail,to_days(now())-to_days(regregdate),date_format(date_add(now(), interval 6 month),'%a, %d %b %Y %k:%i:%s GMT') from registrations where regactivecode='$ENV{QUERY_STRING}'");
$Regs->execute;
@Reg = $Regs->fetchrow;
$Regs->finish;
	
$tt = Template->new({
	INCLUDE_PATH => ['.','/usr/local/git/fpa/htdocs/lib'],
	WRAPPER => 'logicdesign.tt'
});

if ($Regs->rows > 0) {

#  This is an okay activation (for the time being activate no matter how tardy)

#  Set the regactive flag to C, the last login date and the uid cookie

$Sts = $dbh->do("update registrations set reglastlogindate=now(),regactive='C',regactivecode='' where reg_id=$Reg[0]");

#  ... and then display the ready to login screen

	$Vars = {
	title => 'Activation'
	};

	print<<EOD;
Content-Type: text/html
Set-Cookie: fpa-uid=$Reg[2]; path=/; expires=$Reg[4];


<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
<title> | FreePlus Accounts</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<link rel="stylesheet" type="text/css" href="/wp-content/themes/freeplusaccounts/style.css"/>
<link rel="shortcut icon" href="/favicon.ico"/>
<link rel="stylesheet" href="/css/jquery-ui.css" type="text/css"/>
<script type='text/javascript' src='/js/jquery.js'></script> 
<script type='text/javascript' src='/js/jquery-ui.min.js'></script> 
<script src="/wp-content/themes/freeplusaccounts/js/cufon/cufon.js" type="text/javascript"></script>
<script src="/wp-content/themes/freeplusaccounts/js/cufon/font.js" type="text/javascript"></script>
<script src="/wp-content/themes/freeplusaccounts/js/cufon/settings.js" type="text/javascript"></script>
</head>
<body>
  <div class="top-green"></div>
  <div class="m header">
    <a href="/home/" class="logo" title="Free Plus Accounts"><img src="/wp-content/themes/freeplusaccounts/images/logo.jpg" alt="Free Plus Accounts" /></a>
    <div id="freeplustitle"><img src="/wp-content/themes/freeplusaccounts/images/freeplustitle.png" alt="Free Plus Accounts" /></div>
    <div class="listfix" id="nav">
      <div class="menu-header">
        <ul id="menu-main" class="menu">
          <li id="menu-item-24" class="menu-item menu-item-type-post_type menu-item-object-page menu-item-24"><a href="/">Home</a></li> 
          <li id="menu-item-25" class="menu-item menu-item-type-post_type menu-item-object-page menu-item-25"><a href="/about-us/">About Us</a></li> 
          <li id="menu-item-28" class="menu-item menu-item-type-post_type menu-item-object-page menu-item-28"><a href="/features/">Features</a></li> 
          <li id="menu-item-29" class="menu-item menu-item-type-post_type menu-item-object-page menu-item-29"><a href="/tutorials/">Tutorials</a></li> 
          <li id="menu-item-27" class="menu-item menu-item-type-post_type menu-item-object-page menu-item-27"><a href="/faqs/">FAQs</a></li> 
          <li id="menu-item-42" class="menu-item menu-item-type-post_type menu-item-object-page menu-item-42"><a href="/forum/">Forum</a></li> 
          <li id="menu-item-26" class="menu-item menu-item-type-post_type menu-item-object-page menu-item-26"><a href="/contact-us/">Contact Us</a></li> 
        </ul>
      </div>                        
    </div>
    <div class="clear"></div>
  </div>
  <div id="dialog" style="text-align:left;z-index:10100;" title="Errors!"></div>
  <div class="spacer clear line"></div>
  <div class="m whitecontainer">
<div class="leftcol largecol">
  <table width="800" cellspacing="9" cellpadding="9" border="0" style="margin:40px;font-size:16px;line-height:20px;">
    <tr>
      <td><h1>Account Activated</h1></td>
    </tr>
    <tr>
      <td>Thank you for activating your <b><i>FreePlus Account</i></b>.</td>
    <tr>
      <td>When you first log in you will be asked to complete your Company Details and set up any Opening Balances that you may have.&nbsp;&nbsp;Once you have entered those details you should log out and then log back in again so that any changes, such as setting up your VAT details, can take effect.</td>
    </tr>
    <tr>
      <td>We suggest that one of the first things you do is to set up your customer and supplier lists, particularly for those customers to whom you will be sending invoices.&nbsp;&nbsp;Once that is completed you are ready to use <b><i>FreePlus Accounts</i></b>.</td>
    </tr>
    <tr>
      <td style="text-align:center;"><input type="button" name="but1" id="but1" value="Log in to FreePlus Accounts" onclick="location.href='/cgi-bin/fpa/login.pl';"/>
      </td>
    </tr>
  </table>
</div>
    <div class="rightcol smallcol">
      <div style="padding-left:22px;width:200px;"><iframe src="/amazon.html"width="180" height="150" frameborder="0" scrolling="no"></iframe></div>
      <br />
      <div style="position:relative;">
        <div id="starbuy" style="position:absolute;left:130px;top:-25px;"><img src="/adimages/tapbadge.png" width="140" height="119"/></div>
        <a href="http://www.theaccountancy.co.uk" style="border:none;"><img src="/adimages/TAP.png" alt="The Accountancy Partnership"/></a><br />
      </div>
    </div>
    <div class="clear"></div>
  </div>
    <!--- END WHITECONTAINER --->
  <div class="footer-b">
    <div class="m">
      <h3>Latest News Posts</h3>
      <div class="listfix">
        <ul>        </ul>
        <div class="clear"></div>
      </div>
      <div class="clear"></div>
    </div>
  </div>
  <div class="clear"></div>
  <div class="clear"></div>
  <div class="footer">
    <div class="m">
      <div class="logo"><a href="/home/" title="Free Plus Accounts"><img src="/wp-content/themes/freeplusaccounts/images/logo-footer.jpg" alt="Free Plus Accounts" /></a></div>
      <div class="footer-links">
        <div class="listfix">
          <div class="menu-footer-container">
            <ul id="menu-footer" class="menu">
              <li id="menu-item-36" class="menu-item menu-item-type-post_type menu-item-object-page menu-item-36"><a href="http://www.freeplusaccounts.co.uk/">Home</a></li> 
              <li id="menu-item-34" class="menu-item menu-item-type-post_type menu-item-object-page menu-item-34"><a href="http://www.freeplusaccounts.co.uk/about-us/">About Us</a></li> 
              <li id="menu-item-33" class="menu-item menu-item-type-post_type menu-item-object-page menu-item-33"><a href="http://www.freeplusaccounts.co.uk/contact-us/">Contact Us</a></li> 
              <li id="menu-item-31" class="menu-item menu-item-type-post_type menu-item-object-page menu-item-31"><a href="http://www.freeplusaccounts.co.uk/terms-conditions/">Terms &#038; Conditions</a></li> 
              <li id="menu-item-32" class="menu-item menu-item-type-post_type menu-item-object-page menu-item-32"><a href="http://www.freeplusaccounts.co.uk/privacy-policy/">Privacy Policy</a></li> 
            </ul>
          </div>          
        </div>
        <p>&copy; 2011 Free Plus Accounts, All Rights Reserved</p>
      </div>
      <div class="clear"></div>
    </div>
  </div>
</body>
</html>
EOD
}
else {

#  This is not valid, either it is an incorrect activation code or the account has been deleted	

	$Vars = {
	 ads => $Adverts,
		title => 'Activation Error',
	};
	print "Content-Type: text/html\n\n";

	$tt->process('notactivated.tt',$Vars);
}
$dbh->disconnect;
exit;



