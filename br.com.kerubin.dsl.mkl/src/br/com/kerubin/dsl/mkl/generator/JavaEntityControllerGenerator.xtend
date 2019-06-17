package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity
import br.com.kerubin.dsl.mkl.model.Rule
import br.com.kerubin.dsl.mkl.model.Slot

import static br.com.kerubin.dsl.mkl.generator.Utils.*

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.RuleUtils.*

class JavaEntityControllerGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.filter[it.canGenerateController].forEach[generateController]
	}
	
	def generateController(Entity entity) {
		val basePakage = serverGenSourceFolder
		val fileName = basePakage + entity.packagePath + '/' + entity.toControllerName + '.java'
		generateFile(fileName, entity.generateEntityController)
	}
	
	def CharSequence generateEntityController(Entity entity) {
		val entityName = entity.toEntityName
		val entityVar = entity.toEntityName.toFirstLower
		val entityDTOName = entity.toEntityDTOName
		val entityDTOVar = entity.toEntityDTOName.toFirstLower
		val entityServiceVar = entity.toServiceName.toFirstLower
		val idVar = entity.id.name.toFirstLower
		val idType = if (entity.id.isEntity) entity.id.asEntity.id.toJavaType else entity.id.toJavaType
		val toDTO = 'convertEntityToDto'
		val toEntity = 'convertDtoToEntity'
		
		val ruleActions = entity.ruleActions
		val ruleMakeCopies = entity.ruleMakeCopies
		val ruleFormActionsWithFunction = entity.ruleFormActionsWithFunction
		
		'''
		package «entity.package»;
		
		«IF entity.hasAutoComplete»
		import java.util.Collection;
		import org.springframework.web.bind.annotation.RequestParam;
		«ENDIF»
		«IF !ruleActions.empty || !ruleMakeCopies.isEmpty»
		import org.springframework.web.server.ResponseStatusException;
		«ENDIF»
		import java.util.List;
		import java.util.stream.Collectors;
		
		import javax.validation.Valid;
		import org.springframework.beans.factory.annotation.Autowired;
		import org.springframework.web.bind.annotation.RestController;
		import org.springframework.web.bind.annotation.RequestMapping;
		import org.springframework.web.bind.annotation.ResponseStatus;
		import org.springframework.transaction.annotation.Transactional;
		import org.springframework.http.ResponseEntity;
		import org.springframework.http.HttpStatus;
		
		import org.springframework.web.bind.annotation.PathVariable;
		import org.springframework.web.bind.annotation.RequestBody;
		import org.springframework.web.bind.annotation.PostMapping;
		import org.springframework.web.bind.annotation.GetMapping;
		import org.springframework.web.bind.annotation.PutMapping;
		import org.springframework.web.bind.annotation.DeleteMapping;
		
		import org.springframework.data.domain.Page;
		import org.springframework.data.domain.Pageable;
		«service.importPageResult»
		
		
		@RestController
		@RequestMapping("entities/«entityDTOVar»")
		public class «entity.toControllerName» {
			
			@Autowired
			private «entity.toServiceName» «entityServiceVar»;
			
			@Autowired
			«entityDTOName»DTOConverter «entityDTOVar»DTOConverter;
			«IF !ruleFormActionsWithFunction.isEmpty»
			
			@Autowired
			private «entity.toRuleFormActionsWithFunctionName» «entity.toRuleFormActionsWithFunctionName.toFirstLower»;
			«ENDIF»
			
			@Transactional
			@PostMapping
			public ResponseEntity<«entityDTOName»> create(@Valid @RequestBody «entityDTOName» «entityDTOVar») {
				«entityName» «entityVar» = «entityServiceVar».create(«entityDTOVar»DTOConverter.«toEntity»(«entityDTOVar»));
				return ResponseEntity.status(HttpStatus.CREATED).body(«entityDTOVar»DTOConverter.«toDTO»(«entityVar»));
			}
			
			@Transactional(readOnly=true)
			@GetMapping("/{«idVar»}")
			public ResponseEntity<«entityDTOName»> read(@PathVariable «idType» «idVar») {
				try {
					«entityName» «entityVar» = «entityServiceVar».read(«idVar»);
					return ResponseEntity.ok(«entityDTOVar»DTOConverter.«toDTO»(«entityVar»));
				}
				catch(IllegalArgumentException e) {
					return ResponseEntity.notFound().build();
				}
			}
			
			@Transactional
			@PutMapping("/{«idVar»}")
			public ResponseEntity<«entityDTOName»> update(@PathVariable «idType» «idVar», @Valid @RequestBody «entityDTOName» «entityDTOVar») {
				try {
					«entityName» «entityVar» = «entityServiceVar».update(«idVar», «entityDTOVar»DTOConverter.«toEntity»(«entityDTOVar»));
					return ResponseEntity.ok(«entityDTOVar»DTOConverter.«toDTO»(«entityVar»));
				}
				catch(IllegalArgumentException e) {
					return ResponseEntity.notFound().build();
				}
			}
			
			@ResponseStatus(HttpStatus.NO_CONTENT)
			@DeleteMapping("/{«idVar»}")
			public void delete(@PathVariable «idType» «idVar») {
				«entityServiceVar».delete(«idVar»);
			}
			
			@Transactional(readOnly=true)
			@GetMapping
			public PageResult<«entityDTOName»> list(«entity.toEntityListFilterClassName» «entity.toEntityListFilterName.toFirstLower», Pageable pageable) {
				Page<«entityName»> page = «entityServiceVar».list(«entity.toEntityListFilterName.toFirstLower», pageable);
				List<«entityDTOName»> content = page.getContent().stream().map(pe -> «entityDTOVar»DTOConverter.«toDTO»(pe)).collect(Collectors.toList());
				PageResult<«entityDTOName»> pageResult = new PageResult<>(content, page.getNumber(), page.getSize(), page.getTotalElements());
				return pageResult;
			}
			
			«IF entity.hasAutoComplete»
			@Transactional(readOnly=true)
			@GetMapping("/autoComplete")
			public Collection<«entity.toAutoCompleteName»> autoComplete(@RequestParam("query") String query) {
				Collection<«entity.toAutoCompleteName»> result = «entityServiceVar».autoComplete(query);
				return result;
			}
			«ENDIF»
			
			«IF entity.hasListFilterMany»
			«entity.slots.filter[it.isListFilterMany].map[generateListFilterAutoComplete].join»
			«ENDIF»
			
			«IF entity.hasSumFields»
			«entity.generateMethodGetContaPagarSumFields»
			«ENDIF»
			
			«ruleActions.map[generateRuleActions].join»
			«ruleMakeCopies.map[generateRuleMakeCopies].join»
			«ruleFormActionsWithFunction.map[generateRuleFormActionsWithFunction].join('\r\n')»
		}
		'''
	}
	
	def CharSequence generateRuleFormActionsWithFunction(Rule rule) {
		val entity = (rule.owner as Entity)
		val entityName = entity.toEntityName
		val entityVar = entity.toEntityName.toFirstLower
		val entityDTOName = entity.toEntityDTOName
		val entityDTOVar = entity.toEntityDTOName.toFirstLower
		
		val toDTO = 'convertEntityToDto'
		
		val idVar = entity.id.name.toFirstLower
		val idType = if (entity.id.isEntity) entity.id.asEntity.id.toJavaType else entity.id.toJavaType
		
		val function = rule.apply.ruleFunction
		val isFuncReturnThis = function.funcReturnThis
		val isFuncParamThis = function.funcParamThis
		val methodName = entity.toEntityRuleFormActionsFunctionName(function)
		val ruleFuncServiceVar = entity.toRuleFormActionsWithFunctionName.toFirstLower
		
		'''
		@Transactional
		@PutMapping("/«methodName»/{«idVar»}")
		public ResponseEntity<«entityDTOName»> «methodName»(@PathVariable «idType» «idVar», @Valid @RequestBody «entityDTOName» «entityDTOVar») {
			try {
				«IF isFuncReturnThis && isFuncParamThis»
				«entityName» «entityVar» = «ruleFuncServiceVar».«function.methodName.toFirstLower»(«idVar», «entityDTOVar»);
				return ResponseEntity.ok(«entityDTOVar»DTOConverter.«toDTO»(«entityVar»));
				«ELSEIF isFuncReturnThis»
				«entityName» «entityVar» = «ruleFuncServiceVar».«function.methodName.toFirstLower»();
				return ResponseEntity.ok(«entityDTOVar»DTOConverter.«toDTO»(«entityVar»));
				«ELSEIF isFuncParamThis»
				«ruleFuncServiceVar».«function.methodName.toFirstLower»(«idVar», «entityDTOVar»);
				return ResponseEntity.ok(null);
				«ELSEIF !isFuncReturnThis && !isFuncParamThis»
				«ruleFuncServiceVar».«function.methodName.toFirstLower»();
				return ResponseEntity.ok(null);
				«ENDIF»
			}
			catch(IllegalArgumentException e) {
				return ResponseEntity.notFound().build();
			}
		}
		
		'''
	}
	
	def CharSequence generateRuleMakeCopies(Rule rule) {
		val actionName = rule.getRuleActionMakeCopiesName
		val entity = (rule.owner as Entity)
		val entityServiceVar = entity.toServiceName.toFirstLower
		
		val makeCopiesClassName = entity.toEntityMakeCopiesName
		val makeCopiesNameVar = entity.toEntityMakeCopiesName.toFirstLower
		
		'''
		
		@PostMapping("/«actionName»")
		@ResponseStatus(HttpStatus.NO_CONTENT)
		public void «actionName»(@Valid @RequestBody «makeCopiesClassName» «makeCopiesNameVar») {
			try {
				«entityServiceVar».«actionName»(«makeCopiesNameVar»);
			}
			catch(Exception e) {
				throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage(), e);
			}
		}
		'''
	}
	
	def CharSequence generateRuleActions(Rule rule) {
		val actionName = rule.getRuleActionName
		val entity = (rule.owner as Entity)
		val idVar = entity.id.name.toFirstLower
		val idType = if (entity.id.isEntity) entity.id.asEntity.id.toJavaType else entity.id.toJavaType
		val entityServiceVar = entity.toServiceName.toFirstLower
		
		'''
		
		@PutMapping("/«actionName»/{«idVar»}")
		@ResponseStatus(HttpStatus.NO_CONTENT)
		public void «actionName»(@PathVariable «idType» «idVar») {
			try {
				«entityServiceVar».«actionName»(«idVar»);
			}
			catch(IllegalStateException e) {
				throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage(), e);
			}
		}
		'''
	}
	
	def CharSequence generateMethodGetContaPagarSumFields(Entity entity) {
		val sumFieldsName = entity.toEntitySumFieldsName
		val getEntitySumFields = 'get' + sumFieldsName
		val entityServiceVar = entity.toServiceName.toFirstLower
		val listFilterName = entity.toEntityListFilterName
		
		'''
		@GetMapping("/«sumFieldsName.toFirstLower»")
		public «entity.toEntitySumFieldsName» «getEntitySumFields»(«entity.toEntityListFilterClassName» «listFilterName») {
			«sumFieldsName» result = «entityServiceVar».«getEntitySumFields»(«listFilterName»);
			return result;
		}
		'''
	}
	
	def CharSequence generateListFilterAutoComplete(Slot slot) {
		val autoComplateName = slot.toAutoCompleteName
		'''
		
		@GetMapping("/«autoComplateName»")
		public Collection<«autoComplateName.toFirstUpper»> «autoComplateName»(@RequestParam("query") String query) {
			Collection<«autoComplateName.toFirstUpper»> result = «slot.ownerEntity.toServiceName.toFirstLower».«autoComplateName»(query);
			return result;
		}
		'''
	}
	
}