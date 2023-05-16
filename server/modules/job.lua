---@alias gradeKey string starts from 0 (must be string)

---@class xGrade
---@field name string grade name
---@field label string grade label
---@field salary number grade salary
---@field skin_male table grade male skin
---@field skin_female table grade female skin

---@class xJob
---@field name string job name
---@field label string job label
---@field whitelisted boolean | 1 | 0 job whitelisted state
---@field grades table<gradeKey, xGrade>
