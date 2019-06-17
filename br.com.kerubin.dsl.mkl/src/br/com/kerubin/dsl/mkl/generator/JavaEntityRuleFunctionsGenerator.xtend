package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Rule

import static br.com.kerubin.dsl.mkl.generator.Utils.*

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

class JavaEntityRuleFunctionsGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.filter[!getRuleFormActions.empty].forEach[generateRuleFormActions]
	}
	
	def generateRuleFormActions(Entity entity) {
		val basePakage = serverGenSourceFolder
		
		val ruleFormActionsWithFunction = entity.ruleFormActionsWithFunction
		if (!ruleFormActionsWithFunction.empty) {
			val fileName = basePakage + entity.packagePath + '/' + entity.toRuleFormActionsWithFunctionName + '.java'
			generateFile(fileName, entity.doGenerateRuleFormActionsWithFunctionInterface(ruleFormActionsWithFunction))
		}
	}
	
	def CharSequence doGenerateRuleFormActionsWithFunctionInterface(Entity entity, Iterable<Rule> rulesFormActionsFunction) {
		
		'''
		package «entity.package»;
		
		public interface «entity.toRuleFormActionsWithFunctionName» {
			
			«rulesFormActionsFunction.map[it.generateRuleFunction].join»
			
		}
		'''
	}
	
	def CharSequence generateRuleFunction(Rule rule) {
		val function = rule.apply.ruleFunction
		val isFuncReturnThis = function.funcReturnThis
		val isFuncParamThis = function.funcParamThis
		val entity = (rule.owner as Entity)
		val idVar = entity.id.name.toFirstLower
		val idType = if (entity.id.isEntity) entity.id.asEntity.id.toJavaType else entity.id.toJavaType
		
		'''
		«IF isFuncReturnThis»«entity.toEntityName»«ELSE»void«ENDIF» «function.methodName.toFirstLower»(«IF isFuncParamThis»«idType» «idVar», «entity.toDtoName» «entity.fieldName»«ENDIF»);
		'''
	}
	
	
}