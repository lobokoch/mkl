package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Rule

import static br.com.kerubin.dsl.mkl.generator.Utils.*

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.RuleUtils.*

class JavaEntityMakeCopiesGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[generateContaPagarSumFields]
	}
	
	def generateContaPagarSumFields(Entity entity) {
		val rules = entity.ruleMakeCopies
		if (rules.empty) {
			return
		}
		
		val basePakage = clientGenSourceFolder
		val entityFile = basePakage + entity.packagePath + '/' + entity.toEntityMakeCopiesName + '.java'
		generateFile(entityFile, entity.doGenerateContaPagarMakeCopies(rules))
	}
	
	def CharSequence doGenerateContaPagarMakeCopies(Entity entity, Iterable<Rule> rules) {
		val rule = rules.head // Only the first
		
		entity.imports.clear
		
		val isEnableDoc = entity.service.isEnableDoc
		val title = entity.title
		
		val package = '''
		package «entity.package»;
		
		'''
		
		val body = '''
		
		«IF isEnableDoc»
		@ApiModel(description = "Details about «title»")
		«ENDIF»
		public class «entity.toEntityMakeCopiesName» {
			
			«entity.generateFields(rule)»
			«entity.toEntityMakeCopiesName.generateNoArgsConstructor»
			«entity.generateGetters(rule)»
			«entity.generateSetters(rule)»
		
		}
		'''
		
		val imports = '''
		import javax.validation.constraints.Max;
		import javax.validation.constraints.Min;
		import javax.validation.constraints.NotBlank;
		import javax.validation.constraints.NotNull;
		«IF isEnableDoc»
		
		import io.swagger.annotations.ApiModel;
		import io.swagger.annotations.ApiModelProperty;
		«ENDIF»
		'''
		
		package + imports + body 
	}
	
	def CharSequence generateFields(Entity entity, Rule rule) {
		val id = entity.id
		val grouperField = rule.ruleMakeCopiesGrouperSlot
		
		val makeCopies = rule.apply.makeCopiesExpression
		val min = makeCopies.minCopies
		val max = makeCopies.maxCopies
		
		val isEnableDoc = entity.service.isEnableDoc
		
		'''
		@NotNull(message="'«id.name.toFirstUpper»' é obrigatório.")
		«IF isEnableDoc»
		@ApiModelProperty(notes = "«id.title»", required = true)
		«ENDIF»
		private «id.toJavaType» «id.fieldName»;
		
		@Min(value = «min», message = "A quantidade de cópias não pode ser menor que «min».")
		@Max(value = «max», message = "A quantidade de cópias não pode ser maior que «max».")
		«IF isEnableDoc»
		@ApiModelProperty(notes = "Número de cópias", required = true)
		«ENDIF»
		private Long numberOfCopies;
		
		@Min(value = 1, message = "O intervalo não pode ser menor que 1.")
		@Max(value = 1000, message = "O intervalo não pode ser maior que 1000.")
		«IF isEnableDoc»
		@ApiModelProperty(notes = "Campo de referência para intervalo", required = true)
		«ENDIF»
		private Long referenceFieldInterval;
		
		@NotBlank(message = "O campo '«rule.getRuleMakeCopiesGrouperSlotName»' deve ser informado.")
		«IF isEnableDoc»
		@ApiModelProperty(notes = "«grouperField.title»", required = true)
		«ENDIF»
		«grouperField.buildField»;
		'''
		
	}
	
	def CharSequence generateGetters(Entity entity, Rule rule) {
		val id = entity.id
		val grouperField = rule.ruleMakeCopiesGrouperSlot
		
		'''
		
		«id.getGetMethod»
		
		public Long getNumberOfCopies() {
			return numberOfCopies;
		}
		
		public Long getReferenceFieldInterval() {
			return referenceFieldInterval;
		}
		
		«grouperField.getMethod»
		'''
		
	}
	
	def CharSequence generateSetters(Entity entity, Rule rule) {
		val id = entity.id
		val grouperField = rule.ruleMakeCopiesGrouperSlot
		
		'''
		
		«id.setMethod»
		
		public void setNumberOfCopies(Long numberOfCopies) {
			this.numberOfCopies = numberOfCopies;
		}
		
		public void setReferenceFieldInterval(Long referenceFieldInterval) {
			this.referenceFieldInterval = referenceFieldInterval;
		}
		
		«grouperField.setMethod»
		'''
	}
}