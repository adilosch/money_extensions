-- Inofficial Bitvavo Extension (www.bitvavo.com) for MoneyMoney
-- Fetches available data from Bitvavo API
--
-- Username: API-Key
-- Password: API-Secret
--
-- MIT License
--
-- Copyright (c) 2024
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

WebBanking{version = 1.0,
           url = "https://api.bitvavo.com/v2/",
           services = {"bitvavo"},
           description = "Loads crypto assets from Bitvavo"}

local connection = Connection()
local apiKey
local apiSecret
local walletCurrency = "EUR"

-- Helpers -----------------------------------------------------
local function hmac(message, secret)
  return Crypto.hmac(Crypto.sha256, message, secret)
end

local function queryPrivate(path, method, body)
  method = method or "GET"
  body = body or ""
  local timestamp = tostring(os.time() * 1000)
  local preSign = timestamp .. method .. "/" .. path .. body
  local signature = hmac(preSign, apiSecret)
  local headers = {
    ["Bitvavo-Access-Key"] = apiKey,
    ["Bitvavo-Access-Signature"] = signature,
    ["Bitvavo-Access-Timestamp"] = timestamp,
    ["Bitvavo-Access-Window"] = "10000",
    ["Content-Type"] = "application/json"
  }
  local content = connection:request(method, WebBanking.url .. path, body, "application/json", headers)
  return JSON(content):dictionary()
end

local function queryPublic(path)
  local content = connection:request("GET", WebBanking.url .. path)
  return JSON(content):dictionary()
end

-- MoneyMoney --------------------------------------------------
function SupportsBank(protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "bitvavo"
end

function InitializeSession(protocol, bankCode, username, username2, password, username3)
  apiKey = username
  apiSecret = password
end

function ListAccounts(knownAccounts)
  return {
    {
      name = "Bitvavo Wallets",
      owner = "",
      accountNumber = "Crypto",
      portfolio = true,
      currency = walletCurrency,
      type = AccountTypePortfolio
    }
  }
end

function RefreshAccount(account, since)
  local balances = queryPrivate("balance")
  local securities = {}
  for i, entry in ipairs(balances) do
    local total = tonumber(entry.available) + tonumber(entry.inOrder)
    if total > 0 then
      local priceData = queryPublic(entry.symbol .. "-EUR/ticker/price")
      local price = tonumber(priceData.price) or 0
      securities[#securities + 1] = {
        name = entry.symbol,
        quantity = total,
        price = price,
        currency = walletCurrency
      }
    end
  end
  return {securities = securities}
end

function EndSession()
end
