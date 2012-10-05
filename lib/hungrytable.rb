require 'uri'
require 'json'
require 'openssl'
require 'base64'
require 'cgi'
require 'curb'
require 'active_support/core_ext'
require 'hungrytable/version'
require 'hungrytable/config'
require 'hungrytable/request_extensions'
require 'hungrytable/request_header'
require 'hungrytable/request'
require 'hungrytable/get_request'
require 'hungrytable/post_request'
require 'hungrytable/restaurant'
require 'hungrytable/restaurant_search'
require 'hungrytable/restaurant_slotlock'
require 'hungrytable/reservation_make'
require 'hungrytable/reservation_status'
require 'hungrytable/reservation_cancel'

module Hungrytable
  class HungrytableError < StandardError;end

  def error_codes
    {
      152 => { message: 'The email address is not valid.  Please try again.', name: 'VALIDEMAIL' },
      160 => { message: "We're sorry but we were unable to complete you request.  Our technical team has been notified of the problem and will resolve it shortly.  Thank you.", name: "GENERALERROR" },
      197 => { message: "You must select at least one restaurant to search.", name: "PROVIDERESTAURANT" },
      202 => { message: "The time you selected has already passed.  You may wish to check that your computer clock is correct.", name: "PASSEDTIME" },
      274 => { message: "Your phone number must be numeric.", name: "NUMERICPHONE" },
      279 => { message: "Your IP address is not listed as an OpenTable Partner IP.", name: "INVALIDIP" },
      280 => { message: "Key authentication failure", name: "AUTHENTICATEFAIL" },
      281 => { message: "The phone length for the number provided was not a valid length for the country code.", name: "INVALIDPHONELENGTH" },
      282 => { message: "We are currently unable to connect to the restaurant to complete this action. Please try again later.", name: "ERBERROR" },
      283 => { message: "The time you have chosen for your reservation is no longer available.", name: "RESERVATIONNOTAVAIL" },
      285 => { message: "Credit Card transactions are not allowed via OT Web Services.", name: "CCNOTALLOWED" },
      286 => { message: "Large parties are not allowed via OT Web Services.", name: "LARGEPARTYNOTALLOWED" },
      287 => { message: "The restaurant is currently offline.", name: "RESTOFFLINE" },
      288 => { message: "The restaurant is currently unreachable.", name: "RESTUNREACHABLE" },
      289 => { message: "Cancel transaction failed.", name: "CANCELFAIL" },
      294 => { message: "You have not provided enough information to perform the search.", name: "INSUFFICIENTINFORMATION" },
      295 => { message: "No restaurants were found in your search.  Please try again.", name: "NORESTAURANTSRETURNED" },
      296 => { message: "Your search produced no times.", name: "NOTIMESMESSAGE" },
      298 => { message: "The confirmation number is invalid.", name: "VALIDCONFIRMNUMBER" },
      299 => { message: "The reservation status is not available on reservations older than 30 days.", name: "VALIDSTATUSDATE" },
      301 => { message: "The user for the reservation request already has a reservation within 2 hours of the requested time.", name: "VALIDDUPRESERVATION" },
      302 => { message: "No Reservation Activity found.", name: "NORESOHISTORYAVAILABLE" },
      303 => { message: "Invalid User Email. Please re-enter your UserEmail.", name: "INVALIDUSEREMAIL" },
      304 => { message: "Invalid User Password. Please re-enter your password.", name: "INVALIDUSERPASSWORD" },
      305 => { message: "Unable to authenticate user to login. Please try again.", name: "USERAUTHENTICATIONFAIL" },
      306 => { message: "The entered area to search is too large please limit your search to 20 miles.", name: "SEARCHAREATOOLARGE" },
      307 => { message: "The email address(es) you have provided are not in the correct format. Please try again.", name: "INVALIDEMAILADDRESSES" },
      308 => { message: "Your reservation has already been cancelled, please hit the Reload button on your profile to refresh your page", name: "ALREADYCANCELLED" },
      309 => { message: "You must use SSL for this request.", name: "SSLCONNECTIONREQUIRED" },
      310 => { message: "The points requested for this time slot are not available.", name: "INVALIDPOINTREQUEST" },
      311 => { message: "The user account is deactivated.", name: "ACCTDEACTIVATED" },
      313 => { message: "The requested Restaurant was not found.", name: "INVALIDRESTAURANTID" },
      314 => { message: "We already have an account registered to <email address>", name: "MATCHACCOUNT" },
      315 => { message: "A default metro must be provided for a use", name: "PROVIDEMETRO" },
      316 => { message: "The password must be a minimum of 6 characters.", name: "MALFORMEDPASSWORD" },
      317 => { message: "The phone length for the number provided was not a valid length for the country code.", name: "INVALIDPHONE" },
      318 => { message: "Please enter a valid country id for the phone number.", name: "PROVIDEPHONECOUNTRY" },
      319 => { message: "Please enter a valid country id for the mobile phone number.", name: "PROVIDEMOBILEPHONECOUNTRY" },
      321 => { message: "We're sorry, but we could not complete your reservation request because an account cannot have more than two confirmed reservations into the same restaurant for the same day.", name: "VALIDTOOMANYSAMEREST" },
      322 => { message: "The time slot for this reservation is no longer available.", name: "SLOTLOCKUNAVAILABLE" },
      323 => { message: "The service you are trying to access is currently unavailable, please try again later.", name: "SERVICEUNAVAILABLE" },
      324 => { message: "The service experienced a timeout.  Please try again later.", name: "SERVICETIMEOUT" },
      325 => { message: "Invalid number of lookback days, the most you can look back is 8 days.", name: "INVALIDLOOKBACKDAYS" },
      326 => { message: "This service is currently disabled.  Please try again later.", name: "CURRENTLYDISABLED" }
    }
  end
end
