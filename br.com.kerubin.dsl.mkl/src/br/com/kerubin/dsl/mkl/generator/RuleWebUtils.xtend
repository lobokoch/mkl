package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.FieldObject
import br.com.kerubin.dsl.mkl.model.NumberObject
import br.com.kerubin.dsl.mkl.model.Rule
import br.com.kerubin.dsl.mkl.model.RuleTarget
import br.com.kerubin.dsl.mkl.model.RuleWhenExpression
import br.com.kerubin.dsl.mkl.model.RuleWhenOpIsBefore
import br.com.kerubin.dsl.mkl.model.RuleWhenOpIsBetween
import br.com.kerubin.dsl.mkl.model.RuleWhenOpIsNotNull
import br.com.kerubin.dsl.mkl.model.RuleWhenOpIsNull
import br.com.kerubin.dsl.mkl.model.RuleWhenOpIsSame
import br.com.kerubin.dsl.mkl.model.RuleWhenOperator
import br.com.kerubin.dsl.mkl.model.RuleWhenTemporalConstants
import br.com.kerubin.dsl.mkl.model.RuleWhenTemporalValue
import br.com.kerubin.dsl.mkl.model.TemporalFunction
import br.com.kerubin.dsl.mkl.model.TemporalFunctionNextDays
import br.com.kerubin.dsl.mkl.model.TemporalObject

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.model.FormObject
import br.com.kerubin.dsl.mkl.model.RuleWhenOpOnCreate
import br.com.kerubin.dsl.mkl.model.RuleApply
import java.util.Set
import br.com.kerubin.dsl.mkl.model.FieldAndValue
import br.com.kerubin.dsl.mkl.model.NullObject
import br.com.kerubin.dsl.mkl.model.RuleWhenOpIsEquals
import br.com.kerubin.dsl.mkl.model.RuleWhenEqualsValue
import br.com.kerubin.dsl.mkl.model.RuleWhenOpIsNotEquals
import br.com.kerubin.dsl.mkl.model.Slot
import br.com.kerubin.dsl.mkl.model.EntityAndFieldObject
import br.com.kerubin.dsl.mkl.model.StringObject
import br.com.kerubin.dsl.mkl.model.FieldMathExpression
import br.com.kerubin.dsl.mkl.model.TerminalFieldMathExpression

class RuleWebUtils {
	
	def static CharSequence buildRulesForGridRowStyleClass(Entity entity) {
		val rules = entity.rulesWithTargetEnum.filter[it.ruleAsTargetEnum == RuleTarget.GRID_ROWS && it.apply.hasStyleClass]
		
		if (!rules.empty) {
			val entityVar = entity.fieldName
			'''
			applyAndGetRuleGridRowStyleClass(«entityVar»: «entity.toDtoName»): String {
				«rules.map[buildRuleForGridRowStyleClass].join»
			
			    return null;
			}
			'''
		}
	}
	
	def static CharSequence buildRuleForGridRowStyleClass(Rule rule) {
		val resultStrExp = new StringBuilder
		rule.when.expression.buildRuleWhenForGridRowStyleClass(resultStrExp)
		val exp = resultStrExp.toString
		'''
		
		if («exp») {
			return '«rule.apply.getResutValue»';
		}
		'''
	}
	
	def static CharSequence buildRuleApplyForWeb(RuleApply apply, String targetObject, Set<String> imports) {
		var fieldValues = apply.actionExpression.fieldValues
		
		'''
		«fieldValues.map[it.generateActionFieldAssign(targetObject, imports)].join»
		'''
	}
	
	def static CharSequence generateActionFieldAssign(FieldAndValue fieldAndValue, String targetObject, Set<String> imports){
		val slot = fieldAndValue.field.field
		val abstratcValue = fieldAndValue.value
		var String valueExp = null
		if (abstratcValue instanceof FieldObject) {
			val object = (abstratcValue as FieldObject).field
			valueExp = object.buildMethodGet(targetObject)
		}
		else if (abstratcValue instanceof TemporalObject) {
			val object = (abstratcValue as TemporalObject).temporalConstant
			valueExp = object.getTemporalConstantValue(imports)
			if (slot.isDate || slot.isDateTime) {
				valueExp += '.toDate()'
			}
		} 
		else if (abstratcValue instanceof NumberObject) {
			val object = (abstratcValue as NumberObject)
			valueExp = object.value.toString
		} 
		else if (abstratcValue instanceof NullObject) {
			val object = (abstratcValue as NullObject)
			valueExp = object.nullValue
		} 
		
		'''
		«slot.buildMethodSetForTypeScript(valueExp)»
		'''
	}
	
	def static void buildRuleWhenForGridRowStyleClass(RuleWhenExpression expression, StringBuilder resultStrExp) {
		expression.buildRuleWhenExpression(resultStrExp)
	}
	
	def static void buildRuleApplyFieldMathExpression(FieldMathExpression fieldMathExpression, StringBuilder result) {
		var expression = fieldMathExpression
		result.append('(')		
		
		// Execute the left operation
		val left = expression.left
		if (left !== null) {
			left.processTerminalExpression(result)
		}
		
		// Execute a list of right operations and same number of expressions
		val rights = expression.rights
		if (rights !== null && rights.size > 0) {
			var index = 0
			while (index < rights.size) {
				// Trata a operação
				val op = expression.getOperators.get(index)
				val operation = op.literal
				result.concatSB(operation).append('\r\n')
				
				// Execute the right operation
				val rightExpression = rights.get(index)
				rightExpression.processTerminalExpression(result)
				index++
			}
		}
		
		result.append(')')
	}
	
	def static processTerminalExpression(TerminalFieldMathExpression terminalExpression, StringBuilder result) {
		if (terminalExpression.field !== null) {
			terminalExpression.field.addFieldMathExpressionAsNumber(result)
		}
		else {
			terminalExpression.expression.buildRuleApplyFieldMathExpression(result)
		}
	}
		
	def static addFieldMathExpressionAsNumber(FieldObject fieldObject, StringBuilder result) {
		val slot = fieldObject.getField
		if (slot !== null) {
			val entity = slot.ownerEntity
			val thisEntity = 'this.' + entity.fieldName
			result.append('Number(')
			result.append(thisEntity + '.' + slot.fieldName)
			result.append(')')
		}
	}
	
	def static void buildRuleWhenExpression(RuleWhenExpression expression, StringBuilder resultStrExp) {
		val isThis = true
		buildRuleWhenExpression(expression, resultStrExp, isThis);
	}
	
	def static void buildRuleWhenExpression(RuleWhenExpression expression, StringBuilder resultStrExp, boolean isThis) {
		if (expression ===  null) {
			return
		}
		
		var String objName = null
		var String strExpression = null
		var isObjStr = false
		var isObjDate = false
		var isNumber = false
		var isObjForm = false
		var isObjEnum = false
		var Entity entity = null
		var Slot slot = null
		var isObjSlot = false
		var isObjEntityAndField = false
		var Slot fieldEntity = null
		
		if (expression.left.whenObject instanceof FieldObject) {
			slot = (expression.left.whenObject as FieldObject).getField
			isObjSlot = true
			entity = slot.ownerEntity
			if (isThis) {
				objName = 'this.' + slot.ownerEntity.fieldName + '.' + slot.fieldName
			}
			else {
				objName = slot.ownerEntity.fieldName + '.' + slot.fieldName
			}
			isObjStr = slot.isString
			isObjDate = slot.isDate
			isNumber = slot.isNumber
			isObjEnum = slot.isEnum
			strExpression = objName
		}
		else if (expression.left.whenObject instanceof EntityAndFieldObject) {
			isObjEntityAndField = true
			isObjSlot = true
			val entityAndFieldObject = (expression.left.whenObject as EntityAndFieldObject)
			fieldEntity = entityAndFieldObject.fieldEntity
			
			entity = fieldEntity.asEntity
			val slotName = entityAndFieldObject.fieldSlot
			slot = entity.slots.filter[it.name.toLowerCase == slotName.toLowerCase].head
			
			if (isThis) {
				objName = 'this.' + fieldEntity.ownerEntity.fieldName + '.' + fieldEntity.fieldName + '.' + slot.fieldName
			}
			else {
				objName = fieldEntity.ownerEntity.fieldName + '.' + fieldEntity.fieldName + '.' + slot.fieldName
			}
			isObjStr = slot.isString
			isObjDate = slot.isDate
			isNumber = slot.isNumber
			isObjEnum = slot.isEnum
			strExpression = objName
		}
		else if (expression.left.whenObject instanceof TemporalObject) {
			val tObj = expression.left.whenObject as TemporalObject
			objName = tObj.temporalConstant.literal
			strExpression = tObj.temporalConstant.getTemporalConstantValue(null)
			isObjDate = true
		}
		else if (expression.left.whenObject instanceof NumberObject) {
			val tObj = expression.left.whenObject as NumberObject
			objName = tObj.value.toString
			strExpression = objName
			isNumber = true
		}
		else if (expression.left.whenObject instanceof StringObject) {
			val tObj = expression.left.whenObject as StringObject
			objName = tObj.strValue.toString
			strExpression = objName
			isObjStr = true
		}
		else if (expression.left.whenObject instanceof FormObject) {
			isObjForm = true
		}
		
		val op = expression.left.objectOperation
		if (op !== null) {
			if (op instanceof RuleWhenOpIsNull) {
				if (isObjStr) {
					resultStrExp.concatSB('(').append('!').append(objName).concatSB('||').concatSB(objName).append('.trim().length == 0)')						
				}
				else {
					resultStrExp.concatSB('!').append(objName)					
				}
			}
			else if (op instanceof RuleWhenOpIsNotNull) {
				if (isObjStr) {
					resultStrExp.concatSB('(').append(objName).concatSB('||').concatSB(objName).append('.trim().length > 0)')						
				}
				else {
					resultStrExp.concatSB(objName).append(' !== null')				
				}
			}
			else if (op instanceof RuleWhenOpIsBetween) {
				val opIsBetween = op as RuleWhenOpIsBetween
				val dateFrom = opIsBetween.betweenFrom.getTemporalValue
				val dateTo = opIsBetween.betweenTo.getTemporalValue
				if (isObjDate) {
					resultStrExp.concatSB('''«objName.toDateMoment».isBetween(«dateFrom», «dateTo»)''')
				}
				else {
					resultStrExp.concatSB('''(«objName» >= «dateFrom» && «objName» <= «dateTo»)''')					
				}
			}
			else if (op instanceof RuleWhenOpIsSame) {
				val opIsSame = op as RuleWhenOpIsSame
				val value = opIsSame.valueToCompare.getTemporalValue
				if (isObjDate) {
					resultStrExp.concatSB('''«objName.toDateMoment».isSame(«value», 'day')''')
				}
				else {
					resultStrExp.concatSB('''«objName» == «value»''')					
				}
			}
			else if (op instanceof RuleWhenOpIsEquals) {
				val opIsEquals = op as RuleWhenOpIsEquals
				var valueToCompare = opIsEquals.valueToCompare.getRuleWhenEqualsValueForTypeScript(entity, null)
				var objectToCompare = objName
				
				
				val isNotEquals = op instanceof RuleWhenOpIsNotEquals
				
				val isStringValue = (isObjSlot && slot.isEnum) || opIsEquals.valueToCompare.stringObject !== null
				
				if (isNotEquals) {
					if (isStringValue) {
						valueToCompare = "'" + valueToCompare + "'"
						resultStrExp.concatSB('''(String(«objectToCompare») !== «valueToCompare»)''')
					}
					else {
						resultStrExp.concatSB('''(«objectToCompare» === «valueToCompare»)''')
					}
					
				}
				else {
					// String(this.caixaDiario.caixaDiarioSituacao) !== 'NAO_INICIADO';
					if (isStringValue) {
						valueToCompare = "'" + valueToCompare + "'"
						resultStrExp.concatSB('''(String(«objectToCompare») === «valueToCompare»)''')
					}
					else {
						resultStrExp.concatSB('''(«objectToCompare» === «valueToCompare»)''')
					}
					// resultStrExp.concatSB('''«envelopeObjectName».equals(«value»)''')
				}
			}
			else if (op instanceof RuleWhenOpIsBefore) {
				val opIsBefore = op as RuleWhenOpIsBefore
				val value = opIsBefore.valueToCompare.getTemporalValue
				if (isObjDate) {
					resultStrExp.concatSB('''«objName.toDateMoment».isBefore(«value», 'day')''')
				}
				else {
					resultStrExp.concatSB('''«objName» < «value»''')					
				}
			}
			else if (op instanceof RuleWhenOpOnCreate) {
				
			}
		}
		else {
			resultStrExp.concatSB(strExpression)
		}
		
		if (expression.rigth !== null) {
			resultStrExp.concatSB(expression.operator.adaptRuleWhenOperator)
			expression.rigth.buildRuleWhenExpression(resultStrExp, isThis)
		}
	}
	
	def static String getRuleWhenEqualsValueForTypeScript(RuleWhenEqualsValue ruleWhenEqualsValue, Entity entity, Set<String> imports) {
		var objStr = 'UNKNOWN_VALUE'
		if (ruleWhenEqualsValue.enumObject !== null) {
			val enumObject = ruleWhenEqualsValue.enumObject
			// val enumeration = enumObject.enumeration
			val enumItem = enumObject.enumItem
			// TODO: resolve this
			// objStr = enumeration.name + '.' + enumItem
			objStr = enumItem
			// val importValue = entity.getImportExternalEnumeration(enumeration)
			// imports.add(importValue)
		}
		else if (ruleWhenEqualsValue.stringObject !== null) {
			objStr = ruleWhenEqualsValue.stringObject.strValue
		}
		objStr
	}
	
	def static StringBuilder insertSB(StringBuilder sb, String value) {
		if (sb.length > 0) {
			sb.append(' ')
		}
		sb.append(value);
	}
	
	def static String adaptRuleWhenOperator(RuleWhenOperator operator) {
		val opValue = operator.operator
		switch (opValue) {
			case 'and': {
				'&&'
			}
			case 'or': {
				'||'
			}
			default: {
				opValue
			}
		}
	}
	
	def static String getGetTemporalValue(RuleWhenTemporalValue temporalValue) {
		if (temporalValue.temporalObject !== null) {
			val tempObj = temporalValue.temporalObject
			if (tempObj.temporalFuncation !== null) {
				val tempFunc = tempObj.temporalFuncation.getTemporalFuncationValue
				tempFunc
			}
			else {
				val constObj = tempObj.temporalConstant.getTemporalConstantValue(null)
				constObj
			}
		}
		else {
			temporalValue.valueInt.toString
		}
	}
	
	def static String toDateMoment(String objectName) {
		'moment(' + objectName + ')'
	}
	
	def static String getTemporalFuncationValue(TemporalFunction tf) {
		var result = '<INVALID_TEMPORAL_FUNCTION>'
		if (tf instanceof TemporalFunctionNextDays) {
			val func = tf as TemporalFunctionNextDays
			val days = func.days
			result = "moment().add(" + days + ", 'day')"
		}
		result
		
	}
	
	def static String getTemporalConstantValue(RuleWhenTemporalConstants tc, Set<String> imports) {
		if (imports !== null) {
			imports.add("import * as moment from 'moment';")
		}
		switch (tc) {
			case RuleWhenTemporalConstants.TOMORROW: {
				"moment().add(1, 'day')"
			}
			case RuleWhenTemporalConstants.YESTERDAY: {
				"moment().add(-1, 'day')"
			}
			case RuleWhenTemporalConstants.END_OF_WEEK: {
				"moment().endOf('week')"
			}
			default: {
				'moment()' // Now and Today
			}
		}
	}
	
}