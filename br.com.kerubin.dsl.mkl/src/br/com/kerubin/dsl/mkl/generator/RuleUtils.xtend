package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Rule
import br.com.kerubin.dsl.mkl.model.RuleWhenExpression
import br.com.kerubin.dsl.mkl.model.FieldObject
import br.com.kerubin.dsl.mkl.model.TemporalObject
import static extension br.com.kerubin.dsl.mkl.generator.Utils.*
import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import br.com.kerubin.dsl.mkl.model.NumberObject
import br.com.kerubin.dsl.mkl.model.RuleWhenOpIsNull
import br.com.kerubin.dsl.mkl.model.RuleWhenOpIsNotNull
import br.com.kerubin.dsl.mkl.model.RuleWhenOpIsBetween
import br.com.kerubin.dsl.mkl.model.RuleWhenOpIsSame
import br.com.kerubin.dsl.mkl.model.RuleWhenOpIsBefore
import br.com.kerubin.dsl.mkl.model.RuleWhenTemporalConstants
import java.util.Set
import br.com.kerubin.dsl.mkl.model.RuleWhenTemporalValue
import br.com.kerubin.dsl.mkl.model.RuleWhenOperator
import br.com.kerubin.dsl.mkl.model.FieldAndValue
import br.com.kerubin.dsl.mkl.model.NullObject
import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Slot
import br.com.kerubin.dsl.mkl.model.RuleWhenOpIsEquals
import br.com.kerubin.dsl.mkl.model.RuleWhenEqualsValue
import br.com.kerubin.dsl.mkl.model.Enumeration
import br.com.kerubin.dsl.mkl.model.RuleWhenOpIsNotEquals
import br.com.kerubin.dsl.mkl.model.RuleTarget
import br.com.kerubin.dsl.mkl.model.EntityAndFieldObject

class RuleUtils {
	
	def static Slot getRuleMakeCopiesGrouperSlot(Rule rule) {
		rule?.apply?.makeCopiesExpression?.grouperField?.field
	}
	
	def static Slot getRuleMakeCopiesReferenceField(Rule rule) {
		rule?.apply?.makeCopiesExpression?.referenceField?.field
	}
	
	def static String getRuleMakeCopiesGrouperSlotName(Rule rule) {
		rule?.apply?.makeCopiesExpression?.grouperField?.field?.name?.toFirstUpper ?: '<NULL>'
	}
	
	def static CharSequence getRuleActionMakeCopiesName(Rule rule) {
		val actionName = rule?.action?.actionName ?: 'makeCopies' + (rule.owner as Entity).toDtoName
		
		'action' + actionName.toFirstUpper
	}
	
	def static CharSequence getRuleActionName(Rule rule) {
		'action' + rule.action.actionName.toFirstUpper
	}
	
	def static CharSequence getRuleActionWhenName(Rule rule) {
		rule.getRuleActionName + 'When'
	}
	
	def static String buildRuleWhenExpressionForJava(Rule rule, Set<String> imports) {
		if (rule.hasWhen) {
			val resultStrExp = new StringBuilder
			rule.when.expression.buildRuleWhenExpressionForJava(resultStrExp, imports)
			return resultStrExp.toString
		}
		return null
	}
	
	def static findRule(RuleWhenExpression expression) {
		var container = expression.eContainer
		while (container !== null) {
			if (container instanceof Rule) {
				val rule = container as Rule
				return rule
			}
			container = container.eContainer
		}
		
		return null
	}
	
	def static void buildRuleWhenExpressionForJava(RuleWhenExpression expression, StringBuilder resultStrExp, Set<String> imports) {
		if (expression ===  null) {
			return
		}
		
		val rule = expression.findRule
		var isRuleWithSubscribe = false
		if (rule !== null) {
			isRuleWithSubscribe = rule.ruleAsTargetEnum == RuleTarget.SUBSCRIBE
		} 
		
		
		var String objName = null
		var String strExpression = null
		var isObjStr = false
		var isObjDate = false
		var isNumber = false
		// var isObjForm = false
		var isObjEnum = false
		var Slot slot = null
		var isObjSlot = false
		var isObjEntityAndField = false
		var Slot fieldEntity = null
		
		var isThis = false // TODO: only if needed
		
		var Entity entity = if (rule !== null) rule.owner as Entity else null
		
		if (expression.left.whenObject instanceof FieldObject) {
			slot = (expression.left.whenObject as FieldObject).getField
			entity = slot.ownerEntity
			objName = slot.ownerEntity.fieldName + '.' + slot.buildMethodGet
			isObjStr = slot.isString
			isObjDate = slot.isDate
			isNumber = slot.isNumber
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
				objName = 'this.' + fieldEntity.ownerEntity.fieldName + '.' + fieldEntity.fieldName.buildMethodGet + '.' + slot.fieldName.buildMethodGet
			}
			else {
				objName = fieldEntity.ownerEntity.fieldName + '.' + fieldEntity.fieldName.buildMethodGet + '.' + slot.fieldName.buildMethodGet
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
			strExpression = tObj.temporalConstant.getTemporalConstantValueForJava(imports)
			isObjDate = true
		}
		else if (expression.left.whenObject instanceof NumberObject) {
			val tObj = expression.left.whenObject as NumberObject
			objName = tObj.value.toString
			strExpression = objName
			isNumber = true
		}
		
		
		val op = expression.left.objectOperation
		if (op !== null) {
			if (op instanceof RuleWhenOpIsNull) {
				if (isObjStr) {
					resultStrExp.concatSB('(').append(objName.toJavaIsNull(imports)).concatSB('||').concatSB(objName.toJavaIsEmpty)						
				}
				else {
					resultStrExp.concatSB(objName.toJavaIsNull(imports))					
				}
			}
			else if (op instanceof RuleWhenOpIsNotNull) {
				if (isObjStr) {
					resultStrExp.concatSB('(').append(objName.toJavaIsNotNull(imports)).concatSB('&&').concatSB(objName.toJavaIsNotEmpty)						
				}
				else {
					resultStrExp.concatSB(objName.toJavaIsNotNull(imports))					
				}
			}
			else if (op instanceof RuleWhenOpIsBetween) {
				val opIsBetween = op as RuleWhenOpIsBetween
				val dateFrom = opIsBetween.betweenFrom.getTemporalValueForJava(imports)
				val dateTo = opIsBetween.betweenTo.getTemporalValueForJava(imports)
				if (isObjDate) {
					resultStrExp.concatSB(objName.toJavaIsDateBetween(dateFrom, dateTo))
				}
				else {
					resultStrExp.concatSB('''(«objName» >= «dateFrom» && «objName» <= «dateTo»)''')					
				}
			}
			else if (op instanceof RuleWhenOpIsSame) {
				val opIsSame = op as RuleWhenOpIsSame
				val value = opIsSame.valueToCompare.getTemporalValueForJava(imports)
				//if (isObjDate) {
					resultStrExp.concatSB('''«objName».isEqual(«value»)''')
				//}
				//else {
				//	resultStrExp.concatSB('''«objName» == «value»''')					
				//}
			}
			else if (op instanceof RuleWhenOpIsEquals) {
				val opIsEquals = op as RuleWhenOpIsEquals
				val value = opIsEquals.valueToCompare.getRuleWhenEqualsValueForJava(entity, imports)
				if (isRuleWithSubscribe) {
					objName = objName.replace(entity.fieldName, 'envelope.getPayload()')
				}
				
				val isStringValue = opIsEquals.valueToCompare.stringObject !== null
				if (isStringValue) {
					objName += '.toString()'
				}
				
				val isNotEquals = op instanceof RuleWhenOpIsNotEquals
				
				if (isNotEquals) {
					resultStrExp.concatSB('''!(«objName».equals(«value»))''')
				}
				else {
					resultStrExp.concatSB('''«objName».equals(«value»)''')
				}
			}
			else if (op instanceof RuleWhenOpIsBefore) {
				val opIsBefore = op as RuleWhenOpIsBefore
				val value = opIsBefore.valueToCompare.getTemporalValueForJava(imports)
				if (isObjDate) {
					resultStrExp.concatSB('''«objName».isBefore(«value»)''')
				}
				else {
					resultStrExp.concatSB('''«objName» < «value»''')					
				}
			}
		}
		else {
			resultStrExp.concatSB(strExpression)
		}
		
		if (expression.rigth !== null) {
			resultStrExp.concatSB(expression.operator.adaptRuleWhenOperator)
			expression.rigth.buildRuleWhenExpressionForJava(resultStrExp, imports)
		}
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
	
	def static String getRuleWhenEqualsValueForJava(RuleWhenEqualsValue ruleWhenEqualsValue, Entity entity, Set<String> imports) {
		var objStr = 'UNKNOWN_VALUE'
		if (ruleWhenEqualsValue.enumObject !== null) {
			val enumObject = ruleWhenEqualsValue.enumObject
			val enumeration = enumObject.enumeration
			val enumItem = enumObject.enumItem
			objStr = enumeration.name + '.' + enumItem
			val importValue = entity.getImportExternalEnumeration(enumeration)
			imports.add(importValue)
		} 
		else if (ruleWhenEqualsValue.stringObject !== null) {
			objStr = '"' + ruleWhenEqualsValue.stringObject.strValue + '"'
		}
		objStr
	}
	
	def static String getImportExternalEnumeration(Entity entity, Enumeration enumeration) {
		'import ' + entity.getExternalServicePackage + '.' + enumeration.name + ';'
	}
	
	def static String getExternalServicePackage(Entity entity) {
		var domainName = entity.service.domain
		var serviceName = entity.service.name
		
		if (entity.isExternalEntity) {
			domainName = entity?.subscribeEntityEvents?.externalDomain
			serviceName = entity?.subscribeEntityEvents?.externalService
		}
		
		val basePackage = entity.service.configuration.groupId
		basePackage + '.' + domainName?.removeUnderline + '.' + serviceName?.removeUnderline
	}
	
	def static String getTemporalValueForJava(RuleWhenTemporalValue temporalValue, Set<String> imports) {
		if (temporalValue.temporalObject !== null) {
			val constObj = temporalValue.temporalObject.temporalConstant.getTemporalConstantValueForJava(imports)
			constObj
		}
		else {
			temporalValue.valueInt.toString
		}
	}
	
	def static toJavaIsDateBetween(String objectName, String dateFrom, String dateTo) {
		'''(«objectName».isAfter(«dateFrom») && «objectName».isBefore(«dateTo»))'''
	}
	
	def static toJavaIsNotNull(String objectName, Set<String> imports) {
		imports.add('import java.util.Objects;')
		'''Objects.nonNull(«objectName»)'''
	}
	
	def static toJavaIsNotEmpty(String objectName) {
		'''!«objectName».trim().isEmpty()'''
	}
	
	def static toJavaIsNull(String objectName, Set<String> imports) {
		imports.add('import java.util.Objects;')
		'''Objects.isNull(«objectName»)'''
	}
	
	def static toJavaIsEmpty(String objectName) {
		'''«objectName».trim().isEmpty()'''
	}
	
	def static String getTemporalConstantValueForJava(RuleWhenTemporalConstants tc, Set<String> imports) {
		switch (tc) {
			case RuleWhenTemporalConstants.TOMORROW: {
				imports.add('import java.time.LocalDate;')
				'LocalDate.now().plusDays(1)'
			}
			case RuleWhenTemporalConstants.NOW: {
				imports.add('import java.time.LocalDateTime;')
				'LocalDateTime.now()'
			}
			case RuleWhenTemporalConstants.YESTERDAY: {
				imports.add('import java.time.LocalDate;')
				'LocalDate.now().minusDays(1)'
			}
			case RuleWhenTemporalConstants.END_OF_WEEK: {
				imports.add('import java.time.LocalDate;')
				imports.add('import static java.time.temporal.TemporalAdjusters.nextOrSame;')
				imports.add('import static java.time.DayOfWeek.SUNDAY;')
				
				'LocalDate.now().with(nextOrSame(SUNDAY))'
			}
			default: {
				imports.add('import java.time.LocalDate;')
				'LocalDate.now()' // Today
			}
		}
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
			valueExp = object.getTemporalConstantValueForJava(imports)
		} 
		else if (abstratcValue instanceof NumberObject) {
			val object = (abstratcValue as NumberObject)
			valueExp = slot.getNumberValue(object, imports)
			// valueExp = object.value.toString
		} 
		else if (abstratcValue instanceof NullObject) {
			val object = (abstratcValue as NullObject)
			valueExp = object.nullValue
		} 
		
		'''
		«slot.buildMethodSet(targetObject, valueExp)»;
		'''
	}
	
	def static getNumberValue(Slot slot, NumberObject numberObject, Set<String> imports) {
		var value = numberObject.value.toString
		if (slot.isMoney) {
			imports.add('import java.math.BigDecimal;')
			value = 'new BigDecimal(' + value + ')'  
		}
		else if (slot.isInteger) {
			value = 'new Long(' + value + ')' 
		}
		
		value
	}
	
	def static String getTemporalConstantValueForAngularMoment(RuleWhenTemporalConstants tc) {
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
				'moment()' // Today
			}
		}
	}
	
}